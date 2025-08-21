# cc-mirror

claude code 是 Anthropic 推出的 AI Agents 工具，非常的好用，但是其模型价格太贵，现在开源模型比起 claude 模型并不弱。

为了能够轻松愉快的使用 claude code，我写了这个脚本，能够将 claude code 切换为开源模型。

## 支持的平台和模型

### [Siliconflow](https://cloud.siliconflow.cn/i/ybUFvmqK)

- moonshotai/Kimi-K2-Instruct
- Qwen/Qwen3-Coder-480B-A35B-Instruct
- Qwen/Qwen3-235B-A22B-Instruct-2507
- zai-org/GLM-4.5
- Pro/deepseek-ai/DeepSeek-V3

### [DeepSeek](https://platform.deepseek.com/usage)

- deepseek-chat
- deepseek-reasoner

### [Moonshot](https://platform.moonshot.cn/console/account)

- kimi-k2-0711-preview
- kimi-k2-turbo-preview

## 快速开始

以硅基流动为例，其他平台类似。首先需要在相应的模型服务平台注册，并获取 Key。然后运行相应的脚本。


可以将脚本下载到本地运行，运行如下代码即可：

```bash
bash cc_siliconflow.sh
```

也可直接远程安装github仓库的脚本，运行如下代码即可：

```bash
bash -c "$(curl -fsSL https://github.com/kmno4/cc-mirror/raw/main/cc_siliconflow.sh)"
```





