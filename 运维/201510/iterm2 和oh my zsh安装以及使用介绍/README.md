# iterm2 和oh my zsh安装配置详解(MAC 原创)

## 起因

写这篇文章的主要原因是自己参考网上的文章配置过程中遇上了一些问题，导致始终无法正常显示，所以把一些细节更详细的说明

iTerm 2 相比自带的 Terminal 应用，有太多优点了。例如，可以设置主题，支持画面分割，各种使用的快捷键，以及快速唤出。

![ls 效果图](https://github.com/lenxeon/notes/blob/master/%E8%BF%90%E7%BB%B4/201510/iterm2%20%E5%92%8Coh%20my%20zsh%E5%AE%89%E8%A3%85%E4%BB%A5%E5%8F%8A%E4%BD%BF%E7%94%A8%E4%BB%8B%E7%BB%8D/iterm2%E6%95%88%E6%9E%9C%E5%9B%BE.png)

![vim 效果图](https://github.com/lenxeon/notes/blob/master/%E8%BF%90%E7%BB%B4/201510/iterm2%20%E5%92%8Coh%20my%20zsh%E5%AE%89%E8%A3%85%E4%BB%A5%E5%8F%8A%E4%BD%BF%E7%94%A8%E4%BB%8B%E7%BB%8D/iterm2%20vim%20%E6%95%88%E6%9E%9C%E5%9B%BE.png)

## 安装步骤
### 如果你没有Homebrew请先安装Homebrew
```shell
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
设置环境变量
```shell
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile
```
加载环境变量
```shell
source ~/.bash_profile
```
更新
```shell
brew update
```
### 安装iTerm2
```shell
brew cask install iTerm2
```
### 启动iTerm2，从顶上的配置中设置颜色和字体
在 Keys -> Hotkey 中设置 command + option + i 快速显示和隐藏 iTerm
在 Profiles -> Default -> Check silence bell
下载 Solarized
```shell
$ git clone git://github.com/altercation/solarized.git
```
在 Profiles -> Default -> Colors -> Load Presets 将iterm2-colors-solarized里的两个文件导入，并选Solarized Dark作为默认颜色。
