# Typing game

CLI(今の所) タイピングゲーム
英語学習用


## 設定

設定ファイルにするか
```sh
# 設定
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"

# ログ用変数
SESSION_ID="session_$(date +%Y%m%d_%H%M%S)"
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
START_SEC=$(date +%s)

SPEECH_FILE="/dev/shm/say_${SESSION_ID}.mp3"
SPEECH=true
```

## フロー

```mermaid
flowchart TD
    Start([Start]) --> CheckDeps[check_dependencies]
    CheckDeps --> SelectSet[select_word_set<br/>TUI selection]
    SelectSet --> QuitCheck{quit?}
    QuitCheck -->|Yes| End([Exit])
    QuitCheck -->|No| CreateSession[Create JSON session file]
    
    CreateSession --> LoadContent[load_content<br/>man/command words]
    LoadContent --> ShowReady[Show word count<br/>Press ANY KEY]
    ShowReady --> WaitStart[Wait for key press]
    WaitStart --> GameLoop{Game Loop}
    
    GameLoop --> SelectWord[Random word selection]
    SelectWord --> Speech[speech - TTS word]
    Speech --> DisplayWord[Display word]
    DisplayWord --> WaitInput[Read input with timeout]
    
    WaitInput --> CheckQuit{input == 'q'?}
    CheckQuit -->|Yes| SaveSession[Save session end data]
    CheckQuit -->|No| CheckCorrect{input == word?}
    
    CheckCorrect -->|Yes| ShowCorrect[Show ✓ Correct]
    CheckCorrect -->|No| ShowFailed[Show ✗ Failed]
    
    ShowCorrect --> CalcSpeed[Calculate speed c/s]
    ShowFailed --> CalcSpeed
    CalcSpeed --> LogGame[log_game to JSON]
    LogGame --> WaitNext[Wait for Enter]
    WaitNext --> GameLoop
    
    SaveSession --> Cleanup[cleanup<br/>Remove temp files]
    Cleanup --> End
    
    style Start fill:#90EE90
    style End fill:#FFB6C1
    style GameLoop fill:#87CEEB
    style CheckQuit fill:#FFE4B5
    style CheckCorrect fill:#FFE4B5
```

