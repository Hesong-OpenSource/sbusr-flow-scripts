#!/usr/bin/env python
# -*- coding: utf-8 -*-

# -----------------------------------------------------------------------------
# 利用这些脚本函数，可以较为方便的实现 “脚本节点”->"sbusr" 的 RPC 调用
# -----------------------------------------------------------------------------


def recusive_bytes(obj, encoding=None):
    if encoding is None:
        encoding = 'gbk'
    if isinstance(obj, unicode):
        return obj.encode(encoding)
    elif isinstance(obj, (tuple, list)):
        return [sbusr.recusive_bytes(i) for i in obj]
    elif isinstance(obj, dict):
        return dict((sbusr.recusive_bytes(k), sbusr.recusive_bytes(v)) for (k, v) in obj.items())
    else:
        return obj


def choice_addr(client_type=None):
    if client_type is None:
        client_type = 18
    curr_unit_id = GetSvrNodeID()
    local_addrs = []
    remote_addrs = []
    nodeinfos = SmartbusGetNodeInfo(client_type)
    for nodeinfo in nodeinfos:
        unitid, clientid, clienttype, addinfo = nodeinfo
        if unitid == curr_unit_id:
            local_addrs.append((unitid, clientid, clienttype))
        else:
            remote_addrs.append((unitid, clientid, clienttype))
    if local_addrs:
        return randchoice(local_addrs)
    elif remote_addrs:
        return randchoice(remote_addrs)
    else:
        errmsg = 'can not find a smartbus node with whose type is {}'.format(
            client_type)
        TraceErr(errmsg)
        raise Exception(errmsg)


def call(method, params=[], timeout=10, addr=None):
    # 验证 method 参数
    if not isinstance(method, (str, bytes, unicode)):
        raise TypeError('method argument should be a string')
    method = str(method)
    # 验证 method 参数
    if not isinstance(params, (tuple, list, dict)):
        raise TypeError('params arguemnt should be list or dict')
    # 验证 timeout 参数
    timeout = int(timeout * 1000)
    if timeout < 0:
        raise ValueError('timeout must greater than zero')
    # 验证 addr 参数
    if addr is None:  # 如果没有指定地址，就自动选择一个smartbus地址
        addr = sbusr.choice_addr()
    else:  # 如果指定了地址，验证参数的格式
        if not isinstance(addr, (tuple, list)):
            raise TypeError(
                'addr argument should be a three int elements tuple or list')
        if not (
            len(addr) == 3 and
            all([isinstance(i, int) for i in addr])
        ):
            raise ValueError(
                'addr argument should be a three int elements tuple or list')
    unitid, clientid, clienttype = addr
    #
    # JSONRPC 的 ID
    id_ = uuid()
    data = {
        "jsonsbusr": "2.0",
        "id": id_,
        "method": method,
        "params": params,
    }
    # 发送RPC请求
    ret = SmartbusSendData(
        unitid, clientid, clienttype, 1, 211, json.dumps(data, ensure_ascii=False))
    if ret < 0:
        raise RuntimeError(
            'sbusr.call[{}] SmartbusSendData returns {}'.format(id_, ret))
    # 等待RPC回复
    err, retval = AsynchInvoke(SmartbusWaitNotify(id_, 1, timeout))
    if err == 1:    # 等待成功
        res = json.loads(retval)
        res = sbusr.recusive_bytes(res)
        if 'result' in res:
            return 1, res['result']
        elif 'error' in res:
            error = res['error']
            raise RuntimeError('sbusr.call[{}] response error: code={}, message={}, data={}'.format(
                id_, error['code'], error.get('message'), error.get('data')))
        else:
            raise RuntimeError(
                'sbusr.call[{}] error response format: response={}'.format(id_, res))
    else:   # 等待失败
        raise RuntimeError(
            'sbusr.call[{}] SmartbusSendData() error: code={}'.format(id_, err))
