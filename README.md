# 快艇骰子 / KuaiTing Dice

**快艇骰子** 是一款使用 **Godot 4** 制作的暗黑工业风骰子计分游戏。
**KuaiTing Dice** is a dark industrial dice-scoring game made with **Godot 4**.

玩法基于 Yacht / Yahtzee 类骰子计分规则，支持单人、本地双人和局域网联机。
The gameplay is based on Yacht / Yahtzee-style dice scoring, with Single Player, Local Two Player, and LAN Multiplayer modes.

---

## 功能 / Features

* 单人模式 / Single Player
* 本地排行榜 / Local leaderboard
* 本地双人轮流模式 / Local Two Player pass-and-play
* 局域网联机 / LAN Multiplayer
* LAN Host / Join by IP
* LAN Ready / Start Match
* LAN 对局同步 / LAN gameplay synchronization
* LAN 断线保护 / LAN disconnect handling
* 结算页面 / Result screen
* 音效与音量设置 / Sound effects and audio settings
* 暗黑赌桌风格 UI / Dark gambling-table UI

---

## 游戏模式 / Game Modes

### Single Player / 单人模式

玩家独自完成 13 个计分类别，并记录本地最高分和排行榜。
Play through all 13 score categories alone. The game records local best score and leaderboard.

### Local Two Player / 本地双人

两名玩家在同一台设备上轮流游玩。
Two players take turns on the same device.

### LAN Multiplayer / 局域网联机

两名玩家在同一局域网下通过 Host IP 和 Port 联机。
Two players can play over the same local network using Host IP and Port.

---

## LAN 使用方法 / LAN Instructions

### Same Computer Test / 本机双开测试

第一个窗口选择：
First window:

```text
LAN Multiplayer -> Host
```

第二个窗口选择：
Second window:

```text
LAN Multiplayer -> Join
IP: 127.0.0.1
Port: 24567
```

`127.0.0.1` 只适合同一台电脑测试。
`127.0.0.1` is only for testing two instances on the same computer.

### Two Devices / 两台设备

Player 1:

```text
LAN Multiplayer -> Host
```

Player 2:

```text
LAN Multiplayer -> Join
IP: Player 1's Host IP
Port: 24567
```

注意 / Notes:

* 两台设备必须在同一个 Wi-Fi / 局域网。
  Both devices must be on the same Wi-Fi / local network.
* 如果无法连接，请检查 Windows 防火墙。
  If connection fails, check Windows Firewall.
* 当前不支持互联网联机。
  Internet multiplayer is not currently supported.

---

## 操作 / Controls

| 功能 / Action        | 操作 / Input                           |
| ------------------ | ------------------------------------ |
| 掷骰 / Roll          | Click `ROLL`                         |
| HOLD 骰子 / Hold die | Click a die                          |
| 计分 / Score         | Click a score category               |
| 设置 / Settings      | Click `Settings`                     |
| LAN Host           | Click `Host`                         |
| LAN Join           | Enter IP and Port, then click `Join` |

---

## 运行方法 / How to Run

1. Open Godot 4.
2. Import this project.
3. Open:

```text
res://scenes/main.tscn
```

4. Press `F5`.

---

## 项目结构 / Project Structure

```text
assets/      Art, audio, fonts
scenes/      Godot scenes
scripts/     Game code
tools/       Utility scripts
```

主要脚本 / Main scripts:

```text
scripts/core/       Game logic
scripts/screens/    UI screens
scripts/managers/   Save, audio, network managers
scripts/tests/      Scoring tests
```

---

## 当前限制 / Current Limitations

* LAN 需要手动输入 Host IP。
  LAN requires manually entering the Host IP.
* 暂无房间号自动发现。
  No automatic room-code discovery yet.
* 暂无互联网联机。
  No internet multiplayer yet.
* 暂无聊天系统。
  No chat system yet.

---

## 状态 / Status

Playable prototype.

当前支持：
Currently supports:

* Single Player
* Local Two Player
* LAN Multiplayer
* Result Screen
* Local Leaderboard
* Audio Settings
