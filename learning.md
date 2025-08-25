# Shell Scripting 学习指南 - 基于 cc_siliconflow.sh

## 概述
本教程通过分析 `cc_siliconflow.sh` 脚本，系统地学习 Shell 脚本编程。这个脚本展示了实际项目中的 Shell 编程技巧。

## 1. 脚本基础结构

### Shebang 行（第1行）
```bash
#!/bin/bash
```
- **作用**: 指定脚本使用的解释器
- **解释**: `#!` 称为 shebang，告诉系统使用 `/bin/bash` 来执行此脚本
- **重要性**: 确保脚本在不同系统上都能正确执行

### 错误处理（第4行）
```bash
set -e
```
- **作用**: 任何命令执行失败时立即退出脚本
- **示例**: 如果 `npm install` 失败，脚本会立即终止
- **相关命令**: `set +e` 关闭此特性

## 2. 函数定义与使用

### 函数语法（第7-58行）
```bash
show_menu() {
    # 函数内容
}
```
- **作用**: 创建可重用的代码块
- **调用**: 直接写函数名 `show_menu`
- **局部变量**: 使用 `local` 关键字声明函数内变量

### 局部变量示例（第8行）
```bash
local options_count=${#model_options[@]}
```
- **`local`**: 变量只在函数内有效
- **`${#array[@]}`**: 获取数组元素数量
- **`[@]`**: 表示数组的所有元素

## 3. 终端控制与用户交互

### 光标控制（第11-12行）
```bash
for ((i=0; i<options_count+1; i++)); do echo ""; done
tput cuu $((options_count + 1))
```
- **`tput`**: 终端控制工具
- **`cuu N`**: 光标上移 N 行
- **作用**: 为菜单预留空间并定位光标

### 光标显示控制（第15-16行）
```bash
tput civis
trap "tput cnorm; exit" SIGINT
```
- **`civis`**: 隐藏光标
- **`cnorm`**: 显示光标
- **`trap`**: 信号处理，Ctrl+C 时恢复光标并退出

### 读取用户输入（第35行）
```bash
read -s -r -n 1 key
```
- **`read`**: 读取用户输入
- **`-s`**: 静默模式（不显示输入内容）
- **`-r`**: 原始模式（不处理转义字符）
- **`-n 1`**: 只读取1个字符

### 箭头键检测（第36-39行）
```bash
if [[ $key == $'\x1b' ]]; then
    read -s -r -n 2 rest
    key+="$rest"
fi
```
- **`$'\x1b'`**: 转义字符 (ESC)
- **原理**: 箭头键产生3字节序列（ESC + [ + A/B）

## 4. 系统检测与平台兼容性

### 检测操作系统（第63行）
```bash
local platform=$(uname -s)
```
- **`uname -s`**: 获取操作系统名称
- **`$(command)`**: 命令替换，获取命令输出
- **返回值**: "Linux", "Darwin" (macOS), 或其他

### 多平台支持（第65-85行）
```bash
case "$platform" in
    Linux|Darwin)
        # Linux/macOS 特定代码
        ;;
    *)
        echo "Unsupported platform｜暂不支持的系统: $platform"
        exit 1
        ;;
esac
```
- **`case`**: 多条件分支语句
- **`pattern)`**: 匹配模式，`|` 表示或
- **`;;`**: 每个分支结束
- **`*)`**: 默认情况（通配符）

## 5. 命令执行与管道

### 下载并执行脚本（第69行）
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
```
- **`curl -o-`**: 下载内容到标准输出
- **`|`**: 管道，前一个命令输出作为后一个命令输入
- **`bash`**: 执行下载的脚本

### 环境变量加载（第71行）
```bash
\. "$HOME/.nvm/nvm.sh"
```
- **`\.`** 或 **`source`**: 在当前shell执行脚本
- **与子shell区别**: 修改的环境变量在当前shell生效
- **`$HOME`**: 用户家目录环境变量

## 6. 条件判断与版本检查

### 命令存在性检查（第89行）
```bash
if command -v node >/dev/null 2>&1; then
```
- **`command -v`**: 检查命令是否存在
- **`>/dev/null`**: 丢弃标准输出
- **`2>&1`**: 将标准错误重定向到标准输出

### 版本号处理（第90-91行）
```bash
current_version=$(node -v | sed 's/v//')
major_version=$(echo "$current_version" | cut -d. -f1)
```
- **`sed 's/v//'`**: 删除版本号前的 'v'
- **`cut -d. -f1`**: 按点号分隔，取第一个字段（主版本号）
- **`cut` 参数**: `-d` 指定分隔符，`-f` 指定字段

### 数值比较（第93行）
```bash
if [ "$major_version" -ge 18 ]; then
```
- **`[ condition ]`**: 条件测试（旧式语法）
- **`-ge`**: 大于或等于
- **其他比较运算符**:
  - `-eq`: 等于
  - `-ne`: 不等于
  - `-lt`: 小于
  - `-le`: 小于等于
  - `-gt`: 大于

## 7. npm 包管理

### 检查包更新（第112行）
```bash
outdated_info=$(npm outdated -g @anthropic-ai/claude-code || true)
```
- **`npm outdated`**: 检查过时的包
- **`-g`**: 全局包
- **`|| true`**: 如果命令失败，继续执行（忽略错误）

### 解析版本信息（第116-117行）
```bash
current_version=$(echo "$outdated_info" | awk 'NR==2 {print $2}')
latest_version=$(echo "$outdated_info" | awk 'NR==2 {print $4}')
```
- **`awk`**: 强大的文本处理工具
- **`NR==2`**: 处理第二行
- **`{print $2}`**: 打印第二个字段
- **awk 默认**: 按空格分隔字段

### 用户确认（第120行）
```bash
read -p "Do you want to upgrade? (y/N) " -n 1 -r
```
- **`-p "prompt"`**: 显示提示信息
- **`-n 1`**: 只读取一个字符
- **`-r`**: 原始模式

### 正则表达式匹配（第122行）
```bash
if [[ $REPLY =~ ^[Yy]$ ]]; then
```
- **`=~`**: 正则表达式匹配操作符
- **`^[Yy]$`**: 匹配单个字符 Y 或 y
- **`^`**: 行首，`$`: 行尾

## 8. 环境变量配置

### 检测当前shell（第168行）
```bash
current_shell=$(basename "$SHELL")
```
- **`basename`**: 提取路径的最后部分
- **`$SHELL`**: 当前shell的路径
- **示例**: `/bin/bash` → `bash`

### 配置文件选择（第169-173行）
```bash
case "$current_shell" in
    bash) rc_file="$HOME/.bashrc" ;;
    zsh) rc_file="$HOME/.zshrc" ;;
    *) rc_file="$HOME/.profile" ;;
esac
```
- **不同shell的配置文件**:
  - bash: `~/.bashrc`
  - zsh: `~/.zshrc`
  - 其他: `~/.profile`

### 环境变量检查（第176行）
```bash
if [ -f "$rc_file" ] && grep -E -q 'export[[:space:]]+ANTHROPIC_BASE_URL=["'\'']?https://api\.siliconflow\.cn/?["'\'']?' "$rc_file"; then
```
- **`-f "file"`**: 检查文件是否存在
- **`grep -E -q`**: 使用扩展正则表达式，安静模式
- **复杂正则表达式**: 匹配各种引号格式的URL

### 安全读取输入（第188行）
```bash
read -s api_key
```
- **`-s`**: 静默模式，输入不显示（用于密码/API密钥）

## 9. 数组操作

### 数组定义（第201-207行）
```bash
model_options=(
    "moonshotai/Kimi-K2-Instruct"
    "Qwen/Qwen3-Coder-480B-A35B-Instruct"
    "zai-org/GLM-4.5"
    "deepseek-ai/DeepSeek-V3.1"
    "Custom (enter your own model)｜自定义 (手动输入模型)"
)
```
- **语法**: `array=(element1 element2 element3)`
- **访问元素**: `${array[0]}`, `${array[1]}`
- **所有元素**: `${array[@]}`

### 数组长度计算（第212行）
```bash
custom_option_index=$((${#model_options[@]} - 1))
```
- **`$(())`**: 算术扩展
- **`${#array[@]}`**: 数组元素个数
- **计算**: 最后一个元素的索引

## 10. 文件操作

### 临时文件创建（第237行）
```bash
temp_file=$(mktemp)
```
- **`mktemp`**: 创建唯一的临时文件
- **安全**: 自动设置权限，避免安全问题

### 文本过滤（第238-242行）
```bash
grep -v -e "# Claude Code environment variables" \
        -e "export ANTHROPIC_BASE_URL" \
        -e "export ANTHROPIC_API_KEY" \
        -e "export ANTHROPIC_MODEL" \
        -e "export ANTHROPIC_SMALL_FAST_MODEL" "$rc_file" > "$temp_file"
```
- **`grep -v`**: 反转匹配（排除匹配的行）
- **`-e pattern`**: 指定匹配模式
- **`>`**: 输出重定向到文件

### 安全文件替换（第243行）
```bash
mv "$temp_file" "$rc_file"
```
- **`mv`**: 移动/重命名文件
- **原子操作**: 确保配置文件的完整性

### 追加内容到文件（第246-251行）
```bash
echo "" >> "$rc_file"
echo "# Claude Code environment variables" >> "$rc_file"
echo "export ANTHROPIC_BASE_URL=https://api.siliconflow.cn/" >> "$rc_file"
echo "export ANTHROPIC_API_KEY=$api_key" >> "$rc_file"
echo "export ANTHROPIC_MODEL=$selected_model" >> "$rc_file"
echo "export ANTHROPIC_SMALL_FAST_MODEL=$selected_model" >> "$rc_file"
```
- **`>>`**: 追加到文件末尾
- **`echo`**: 输出文本内容

## 11. 脚本执行流程总结

1. **初始化**: 设置错误处理，定义函数
2. **环境检查**: 检查Node.js，安装或更新
3. **包管理**: 检查Claude Code，安装或更新
4. **配置**: 设置跳过onboarding
5. **用户交互**: 获取API密钥，选择模型
6. **文件操作**: 更新环境变量配置
7. **完成**: 显示使用说明

## 12. 最佳实践总结

### 错误处理
```bash
set -e  # 出错立即退出
command || true  # 忽略特定错误
command > /dev/null 2>&1  # 丢弃输出
```

### 跨平台兼容
```bash
# 检测系统类型
local platform=$(uname -s)
case "$platform" in
    Linux|Darwin) # 支持的系统
    *) # 不支持的退出
```

### 用户友好
```bash
# 多语言提示
echo "英文提示｜中文提示"
# 进度反馈
echo "✅ 操作完成"
echo "🚀 开始安装"
```

### 安全考虑
```bash
read -s  # 敏感信息静默输入
trap  # 清理处理
mktemp  # 安全临时文件
```

这个脚本展示了生产环境中Shell脚本的最佳实践，包括错误处理、用户交互、跨平台兼容性和代码组织。

## 下一步学习建议

1. **实践**: 尝试修改脚本添加新功能
2. **阅读**: 查看其他开源项目的Shell脚本
3. **工具**: 学习 `sed`, `awk`, `grep` 等文本处理工具
4. **调试**: 使用 `set -x` 调试脚本执行过程