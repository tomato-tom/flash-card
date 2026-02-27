# Typing game

CLI タイピングゲーム

## Directory Structure
```
typing.sh
typing_stats.sh
data/
└── typing/
        └── session_YYYYMMDD_HHMMSS.json
docs/
└── typing.md
```

## typing.sh

```mermaid
flowchart TD
    Start[Start Script] --> Deps[Check Dependencies]
    Deps -->|Missing| Exit[Exit]
    Deps -->|OK| Menu[Select Difficulty]
    Menu -->|Quit| Exit
    Menu -->|Select| Init[Create JSON Log]
    Init --> Load[Load Content]
    Load --> Loop{Game Loop}
    
    subgraph Gameplay ["Gameplay Loop"]
        Loop --> Pick[Pick Random Word]
        Pick --> Speech[TTS Speech]
        Speech --> Input[User Input]
        Input -->|q| EndLoop[End Loop]
        Input -->|Type| Check{Correct?}
        Check -->|Yes| Result[Log Success]
        Check -->|No| Result[Log Failure]
        Result --> Speed[Calc Speed]
        Speed --> Next{Next?}
        Next -->|Enter| Loop
        Next -->|q| EndLoop
    end

    EndLoop --> Save[Update JSON End Time]
    Save --> Clean[Cleanup Temp Files]
    Clean --> Done[End Session]

    style Gameplay fill:#f9f9f9,stroke:#333,stroke-dasharray: 5 5
```

## typing_stats.sh

### Execution Flowchart

```mermaid
flowchart TD
    Start([Start]) --> ParseArgs[parse_arguments]
    ParseArgs --> CheckCustom{Custom range?}
    
    CheckCustom -->|Yes| ValidateRange[validate_custom_range]
    CheckCustom -->|No| ComputeBound[compute_boundaries]
    
    ValidateRange --> SetCustom[PERIOD = custom]
    SetCustom --> ComputeBound
    
    ComputeBound --> GetFiles[get_target_files]
    
    GetFiles --> CalcStats[calculate_stats]
    
    CalcStats --> JqProc[jq: flatten games + filter + aggregate]
    JqProc --> StatsReady{Stats computed?}
    
    StatsReady -->|Success| FormatOut[format_output]
    StatsReady -->|Error| LogFatal[log_fatal + exit]
    
    FormatOut --> Display[Print formatted stats]
    Display --> End([End])
    
    LogFatal --> End
```

---

### Function Dependency Chart

```mermaid
flowchart LR
    subgraph Main_Layer
        main[main]
    end
    
    subgraph Control_Layer
        parse_arguments
        validate_custom_range
        compute_boundaries
        get_target_files
    end
    
    subgraph Core_Layer
        calculate_stats
        jq_engine[jq filter engine]
    end
    
    subgraph Presentation_Layer
        format_output
    end
    
    subgraph Utilities
        log_error
        log_fatal
        show_help
    end
    
    %% Dependencies
    main --> parse_arguments
    main --> validate_custom_range
    main --> compute_boundaries
    main --> get_target_files
    main --> calculate_stats
    main --> format_output
    
    parse_arguments --> show_help
    parse_arguments --> log_fatal
    
    validate_custom_range --> log_fatal
    validate_custom_range --> log_error
    
    compute_boundaries --> log_error
    
    get_target_files --> log_fatal
    
    calculate_stats --> jq_engine
    calculate_stats --> log_fatal
    
    format_output --> log_error
    
    %% Styling
    classDef mainLayer fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef controlLayer fill:#fff9c4,stroke:#fbc02d
    classDef coreLayer fill:#e8f5e9,stroke:#2e7d32
    classDef presentLayer fill:#f3e5f5,stroke:#7b1fa2
    classDef utilLayer fill:#ffebee,stroke:#c62828,stroke-dasharray:5 5
    
    class main mainLayer
    class parse_arguments,validate_custom_range,compute_boundaries,get_target_files controlLayer
    class calculate_stats,jq_engine coreLayer
    class format_output presentLayer
    class log_error,log_fatal,show_help utilLayer
```

---

### Data Flow in `calculate_stats`

```mermaid
graph LR
    subgraph Input
        Files[JSON files]
        Args[--start / --end]
    end
    
    subgraph jq_Processing
        Flatten[Flatten: session + games]
        AttachMeta[Attach: source/level/session_id]
        FilterPeriod[Filter by timestamp]
        FilterCorrect[Filter: input == word]
        Aggregate[Aggregate metrics]
        ComputeDerived[Compute: accuracy/CPS]
        BuildOutput[Build result object]
    end
    
    subgraph Output
        StatsJSON[JSON stats object]
    end
    
    Files --> Flatten
    Args --> FilterPeriod
    
    Flatten --> AttachMeta
    AttachMeta --> FilterPeriod
    FilterPeriod --> FilterCorrect
    FilterCorrect --> Aggregate
    Aggregate --> ComputeDerived
    ComputeDerived --> BuildOutput
    BuildOutput --> StatsJSON
    
    classDef io fill:#f5f5f5,stroke:#666,stroke-width:1px
    classDef proc fill:#e3f2fd,stroke:#1976d2
    class Input,Output io
    class jq_Processing proc
```

---

### Function Call Hierarchy (Tree View)

```mermaid
classDiagram
    class main {
        +void main(args)
    }
    
    class ArgumentHandling {
        +void parse_arguments()
        +void show_help()
        +void validate_custom_range()
    }
    
    class DateFileHandling {
        +void compute_boundaries()
        +string[] get_target_files()
    }
    
    class StatsEngine {
        +object calculate_stats(files)
        >> jq filter: flatten/filter/aggregate
    }
    
    class OutputFormatter {
        +void format_output(stats, period_name)
        >> jq filter: format strings
    }
    
    class Utils {
        +void log_error(msg)
        +void log_fatal(msg)
    }
    
    main --> ArgumentHandling : calls
    main --> DateFileHandling : calls
    main --> StatsEngine : calls
    main --> OutputFormatter : calls
    main --> Utils : error handling
    
    ArgumentHandling --> Utils : on error
    DateFileHandling --> Utils : on error
    StatsEngine --> Utils : on jq failure
    
    note for StatsEngine "Single entry point\nHandles both 'latest' and\nperiod-based aggregation"
```
