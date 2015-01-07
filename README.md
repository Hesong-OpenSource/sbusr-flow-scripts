sbusr-flow-scripts
====================

该项目集合了可在和声 IPSC Flow 中使用的，调用 [sbusr](https://github.com/Hesong-OpenSource/sbusr) 的远程方法时，用于简化脚本的一些自定义函数

# 代码库

http://github.com/Hesong-OpenSource/sbusr-flow-scripts

# 用法

1. 将 `sbusr.fun` 复制到要使用它的流程项目的 `script` 目录
2. 在流程设计器中编辑该项目的属性，将这个路程文件加入项目，保存并重新生成项目属性
3. 在流程的脚本节点使用其中的函数

# 脚本函数说明

## RPC 调用

### 函数定义

sbusr.call(method, params=[], timeout=10, addr=None)

* str method: RPC 方法名
* list|dict params: RPC 参数。应传入 list 或者 dict，前者表示占位参数，后者表示命名参数
* int timeout: 等待 RPC 返回的超时时间，单位是秒
* (int, int, int) addr: 向该使用该 Smartbus 地址的 sbusr 实例发送 RPC 请求。如果为  `None` ，该函数会自动选择一个可用的 sbusr 实例。该参数的三个元素分别是 `unitid`, `clientid`, `clientype`

* 返回值：RPC的返回值，可能是任意JSON类型

### 例子

```python
res = AsynchInvoke(call(method="echo", params=["Hello!"]))
```