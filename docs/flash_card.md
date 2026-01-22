# Flash Card

英単語を覚える
表に英語、裏に日本語の意味を表示

## 機能

単語・フレーズリストよりランダムにカードに表示
ユーザー自己評価
出題頻度調整



## 設計

基本フロー
```mermaid
flowchart TD
    Start([Start Flash Card App]) --> Initialize[Initialize App]
    
    Initialize --> LoadData[Load Data Files]
    LoadData --> CheckEmpty{Content Empty?}
    
    CheckEmpty -->|Yes| CreateSample[Create Sample Content]
    CreateSample --> ShowMenu
    
    CheckEmpty -->|No| ShowMenu[Show Main Menu]
    
    ShowMenu --> MenuChoice{User Choice}
    
    MenuChoice -->|Study| PrepareSession[Prepare Study Session]
    MenuChoice -->|Add Cards| AddCards[Add New Cards]
    MenuChoice -->|View Stats| ShowStats[Show Statistics]
    MenuChoice -->|Exit| ExitApp[Exit Application]
    
    PrepareSession --> LoadPriority[Load & Sort by Priority]
    LoadPriority --> SelectCards[Select Top N Cards]
    SelectCards --> StudyLoop[Begin Study Loop]
    
    StudyLoop --> ShowCard[Show Card Front]
    ShowCard --> WaitInput[Wait for Input]
    
    WaitInput --> InputChoice{User Input}
    
    InputChoice -->|Space/Enter| RevealAnswer[Reveal Answer]
    InputChoice -->|e (Easy)| RecordEasy[Record: Easy]
    InputChoice -->|m (Medium)| RecordMedium[Record: Medium]
    InputChoice -->|h (Hard)| RecordHard[Record: Hard]
    InputChoice -->|q (Quit)| EndSession[End Session]
    InputChoice -->|n (Next)| NextCard[Next Card]
    
    RevealAnswer --> WaitEvaluation[Wait for Evaluation]
    WaitEvaluation --> EvalChoice{e/m/h?}
    
    EvalChoice --> RecordEasy
    EvalChoice --> RecordMedium
    EvalChoice --> RecordHard
    
    RecordEasy --> UpdatePriorityEasy[Update Priority: Lower<br>Easy = priority × 0.7]
    RecordMedium --> UpdatePriorityMedium[Update Priority: Slightly Lower<br>Medium = priority × 1.2]
    RecordHard --> UpdatePriorityHard[Update Priority: Increase<br>Hard = priority × 1.5]
    
    UpdatePriorityEasy --> SaveEvaluation[Save Evaluation Data]
    UpdatePriorityMedium --> SaveEvaluation
    UpdatePriorityHard --> SaveEvaluation
    
    SaveEvaluation --> UpdateNextReview[Update Next Review Date]
    UpdateNextReview --> MoreCards{More Cards?}
    
    MoreCards -->|Yes| NextCard
    NextCard --> ShowCard
    
    MoreCards -->|No| EndSession
    
    EndSession --> UpdateStats[Update Statistics]
    UpdateStats --> ShowSummary[Show Session Summary]
    ShowSummary --> SaveSession[Save Session Log]
    SaveSession --> ShowMenu
    
    AddCards --> InputText[Input Card Text]
    InputText --> InputTranslation[Input Translation]
    InputTranslation --> SetInitialPriority[Set Initial Priority]
    SetInitialPriority --> SaveCard[Save New Card]
    SaveCard --> ShowMenu
    
    ShowStats --> DisplayStats[Display Statistics Dashboard]
    DisplayStats --> ShowMenu
    
    ExitApp --> Cleanup[Save & Cleanup]
    Cleanup --> End([End])
    
    style Start fill:#e1f5fe
    style End fill:#ffebee
    style StudyLoop fill:#f3e5f5
    style RecordEasy fill:#e8f5e8
    style RecordMedium fill:#fff3e0
    style RecordHard fill:#ffebee
```

自己評価により以降の出題頻度変更
Easy: わかる
Medium: まあまあ
Hard: わからない -> 出題頻度上げ

