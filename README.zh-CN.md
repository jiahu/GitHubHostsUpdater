# GitHub Hosts 自动更新工具

[English](README.md)

自动更新 Windows hosts 文件，使用 [GitHub520](https://github.com/521xueweihan/GitHub520) 项目条目，改善受限网络环境下的 GitHub 访问。

## 功能特性

- 从 GitHub520 项目获取最新的 hosts 条目
- 仅更新 hosts 文件中的托管区域（保留您的自定义条目）
- 每次更新前自动创建备份
- 刷新 DNS 缓存以立即生效
- 通过 Windows 任务计划程序每日自动运行

## 系统要求

- Windows 10 或 11
- PowerShell 5.1+（系统内置）
- 管理员权限（脚本需要时会自动提升权限）

## 安装步骤

1. **下载脚本**到本地计算机：

   ```powershell
   # 示例：保存到用户脚本文件夹
   mkdir "$env:USERPROFILE\Scripts" -ErrorAction SilentlyContinue
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jiahu/GitHubHostsUpdater/main/src/update-github-hosts.ps1" -OutFile "$env:USERPROFILE\Scripts\update-github-hosts.ps1"
   ```

   或者克隆本仓库：
   ```powershell
   git clone https://github.com/jiahu/GitHubHostsUpdater.git
   ```

2. **测试脚本**（模拟执行模式）：

   ```powershell
   .\update-github-hosts.ps1 -WhatIf
   ```

   这将显示脚本会执行什么操作，但不会实际修改 hosts 文件。

3. **手动运行脚本**（首次运行）：

   ```powershell
   .\update-github-hosts.ps1 -Verbose
   ```

   脚本将：
   - 需要时自动提升为管理员权限（UAC 提示）
   - 获取最新的 GitHub520 hosts 条目
   - 在 hosts 文件中创建托管区域（首次运行）
   - 在 `C:\Windows\System32\drivers\etc\hosts.bak` 创建备份
   - 刷新 DNS 缓存

## 使用方法

### 基本更新
```powershell
.\update-github-hosts.ps1
```

运行更新。如果远程内容有变化，将更新托管区域。

### 模拟执行模式
```powershell
.\update-github-hosts.ps1 -WhatIf
```

显示将要执行的操作，但不修改任何文件。适用于测试。

### 详细日志
```powershell
.\update-github-hosts.ps1 -Verbose
```

显示每个步骤的详细信息（获取、比较、更新）。

### 强制更新
```powershell
.\update-github-hosts.ps1 -Force
```

跳过变更检测，即使内容未变化也强制执行更新。

### 回滚
```powershell
.\update-github-hosts.ps1 -Rollback
```

从备份文件（`hosts.bak`）恢复 hosts 文件。当 GitHub520 条目导致问题时使用。

您也可以手动回滚：
```powershell
Copy-Item "C:\Windows\System32\drivers\etc\hosts.bak" "C:\Windows\System32\drivers\etc\hosts" -Force
ipconfig /flushdns
```

## 设置每日自动运行

使用 Windows 任务计划程序在每天凌晨 3:47 运行脚本：

### 方法一：PowerShell 脚本（推荐）

将以下内容保存为 `setup-task.ps1` 并以管理员身份运行：

```powershell
$scriptPath = "D:\Tools\GitHubHosts\src\update-github-hosts.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -Daily -At "3:47am"

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "GitHub Hosts 更新工具" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Description "每日更新 hosts 文件中的 GitHub520 条目"
```

### 方法二：任务计划程序图形界面

1. 打开任务计划程序（在开始菜单中搜索）
2. 点击"创建任务"（不是"创建基本任务"）
3. **常规选项卡**：
   - 名称：`GitHub Hosts 更新工具`
   - 勾选"使用最高权限运行"
   - 配置为：Windows 10
4. **触发器选项卡**：
   - 点击"新建"
   - 设置：每天，凌晨 3:47
   - 勾选"已启用"
5. **操作选项卡**：
   - 点击"新建"
   - 操作：启动程序
   - 程序或脚本：`powershell.exe`
   - 添加参数：`-ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\Tools\GitHubHosts\src\update-github-hosts.ps1"`
6. **条件选项卡**：
   - 取消勾选"只有在计算机使用交流电源时才启动任务"（可选）
7. 点击"确定"

## 工作原理

### 托管区域

脚本在 hosts 文件中维护一个 delimited 区域：

```
# BEGIN GitHub520 (2026-09-22)
140.82.114.4    github.com
192.30.255.116  api.github.com
# ... 更多条目 ...
# END GitHub520
```

只有 `# BEGIN GitHub520` 和 `# END GitHub520` 之间的内容会被修改。hosts 文件中的所有其他条目（自定义域名、广告拦截器、本地开发环境）都将保持不变。

### 变更检测

脚本计算远程内容的 SHA256 哈希值，并与本地托管区域进行比较。如果哈希值匹配，则不执行更新（除非使用 `-Force` 参数）。

### 备份

每次更新前，脚本会在 `C:\Windows\System32\drivers\etc\hosts.bak` 创建备份。这是一个单一文件，每次更新时会被覆盖。使用 `-Rollback` 参数从此备份恢复。

## 故障排除

### 脚本未更新
- 检查网络连接
- 验证远程 URL 可访问：`Invoke-WebRequest https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts`
- 使用 `-Verbose` 参数查看详细错误信息

### Hosts 文件未修改
- 确保脚本以管理员权限运行
- 检查防病毒或安全软件是否阻止了修改
- 查看控制台输出中的验证错误信息

### 更新后 DNS 解析不正确
- 手动刷新 DNS：`ipconfig /flushdns`
- 重启浏览器或网络适配器
- 如需要，重启计算机

### 需要回滚
```powershell
.\update-github-hosts.ps1 -Rollback
```

或手动操作：
```powershell
Copy-Item "C:\Windows\System32\drivers\etc\hosts.bak" "C:\Windows\System32\drivers\etc\hosts" -Force
ipconfig /flushdns
```

### 任务计划程序未运行
- 打开任务计划程序并检查任务状态
- 验证任务是否设置为"使用最高权限运行"
- 检查任务历史记录中的错误信息
- 确保脚本路径正确

## 安全说明

- 脚本从公共 GitHub URL 下载内容。请验证 URL 正确并信任 GitHub520 项目。
- 脚本需要管理员权限来修改 hosts 文件。
- `.bak` 文件包含您之前的 hosts 文件内容。如有需要，请妥善保护该文件。
- 在运行脚本之前，请查看脚本源代码以确保您了解其功能。

## 许可证

本脚本按原样提供，仅供个人使用。GitHub520 项目由 [521xueweihan](https://github.com/521xueweihan/GitHub520) 维护。

## 支持

有关 GitHub520 hosts 条目本身的问题，请访问 [GitHub520 项目](https://github.com/521xueweihan/GitHub520)。

有关本脚本的问题，请查看上面的故障排除部分，或在 [GitHub Hosts Updater 仓库](https://github.com/jiahu/GitHubHostsUpdater)中[提交 issue](https://github.com/jiahu/GitHubHostsUpdater/issues)。
