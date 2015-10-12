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

### 把 zsh 设置成默认的 shell
```shell
chsh -s /bin/zsh
```
输入密码，重新打开一个shell窗口，这时已经不是bash了

### 安装 oh-my-zsh
```shell
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
```
### 备份zsh的配置，并用oh-my-zsh的模板创建一个新的配置
```shell
cp ~/.zshrc ~/.zshrc.orig
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
```
### 往 ~/.zshrc 里追加下面的内容

```shell
if [ -x /usr/bin/dircolors ]; then
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias tree='tree -C'
fi

alias ..="cd .."
alias ..2="cd ../.."
alias ..3="cd ../../.."
alias ..4="cd ../../../.."
alias ..5="cd ../../../../.."
alias  "l"="ls -ahl --full-time"

#这一段是为了解决mac的ls命令没有颜色区分的问题
if brew list | grep coreutils > /dev/null ; then
  PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
  alias ls='ls -F --show-control-chars --color=auto'
  eval `gdircolors -b $HOME/.dir_colors`
fi
```

重新打开一个shell窗口执行ls现在已经有颜色了










