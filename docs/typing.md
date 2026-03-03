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
    Start[Start Script] --> Menu[Select Difficulty]
    Menu -->|Quit| Exit
    Menu -->|Select| Init[Create JSON Log]
    Init --> Load[Load Content]
    Load --> Loop{Game Loop}
    
    subgraph Gameplay ["Gameplay Loop"]
        Loop --> Pick[Pick Random Word]
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
    ParseArgs --> Prep[compute_boundaries + get_files]
    
    Prep --> DetectBackend[detect_backend]
    
    DetectBackend --> CheckEnv{Env Var Set?}
    CheckEnv -->|Yes| UseEnv[Use TYPING_STATS_BACKEND]
    CheckEnv -->|No| CheckCmd{duckdb exists?}
    
    CheckCmd -->|Yes| UseDuckDB[Backend: duckdb]
    CheckCmd -->|No| UseJQ[Backend: jq]
    
    UseEnv --> ValidateBackend{Valid?}
    ValidateBackend -->|Yes| Route
    ValidateBackend -->|No| Fatal[log_fatal]
    
    UseDuckDB --> Route[calculate_stats]
    UseJQ --> Route
    
    Route --> Impl{Which Impl?}
    Impl -->|DuckDB| SQLExec[duckdb -json + SQL]
    Impl -->|jq| JQExec[jq -s + filter]
    
    SQLExec --> Normalize[jq '.[0]' normalization]
    JQExec --> Normalize
    
    Normalize --> FormatOut[format_output]
    FormatOut --> Display[Print Stats]
    Display --> End([End])
    
    Fatal --> End
```

---

### Function Dependency Chart

```mermaid
flowchart LR
    subgraph Input
        Args[CLI Args]
        Files[JSON Files]
    end
    
    subgraph Processing
        Parse[parse_arguments]
        Boundaries[compute_boundaries]
        Backend{detect_backend}
        DuckDB[calculate_stats_duckdb]
        JQ[calculate_stats_jq]
    end
    
    subgraph Output
        Format[format_output]
        Display[Terminal]
    end
    
    Args --> Parse
    Files --> Backend
    Parse --> Boundaries
    Boundaries --> Backend
    Backend --> DuckDB
    Backend --> JQ
    DuckDB --> Format
    JQ --> Format
    Format --> Display
```

### Data Flow in `calculate_stats`

```mermaid
graph LR
    subgraph Input
        Files[JSON files]
        Args[--start / --end]
    end
    
    subgraph Processing
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
    class Processing proc
```


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
        +void detect_backend()
        +object calculate_stats(files)
        +object calculate_stats_duckdb(files)
        +object calculate_stats_jq(files)
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
