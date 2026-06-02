# StockNote 股记

A lightweight iOS app for managing stock watchlists with tags and tracking investment strategies.

## Features

- **Tag-based Watchlist**: Organize stocks with multiple tags (not just groups)
- **Strategy Management**: Track buy/sell transactions, calculate positions and NAV
- **Real-time Quotes**: Powered by EastMoney (free, no API key required)
- **Charts**: Sparklines, NAV curves, position pie charts (detailed charts via 同花顺/东方财富)
- **Widgets**: Home screen price display (coming soon)

## Requirements

- iOS 17.0+
- Xcode 15.4+ (for building)

## Development

This project uses GitHub Actions for CI/CD. No local Xcode installation required.

### Building

Push to `main` or `develop` branch triggers automatic build and test:

```bash
git push origin main
```

### Releasing

Create a GitHub release to trigger TestFlight deployment:

```bash
git tag v1.0.0
git push origin v1.0.0
# Then create release on GitHub
```

### GitHub Actions Minutes

- macOS runner costs 10x Linux (~$0.08/min)
- Typical build: 15-20 minutes = ~$1.20-$1.60
- Free tier: effectively ~200 macOS minutes/month

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   iOS App                       │
│  ┌───────────┐  ┌───────────┐  ┌─────────────┐ │
│  │ SwiftData │  │  SwiftUI  │  │ UserDefaults│ │
│  │ (Local)   │  │  Views    │  │ (Settings)  │ │
│  └───────────┘  └───────────┘  └─────────────┘ │
└────────────────────────┼────────────────────────┘
                         │
       ┌─────────────────┼─────────────────┐
       │                 │                 │
  ┌────┴────┐      ┌────┴────┐      ┌────┴────┐
  │EastMoney│      │ Tushare │      │ AkShare │
  │  (free) │      │(optional)│     │ (backup)│
  └─────────┘      └─────────┘      └─────────┘
```

## License

MIT
