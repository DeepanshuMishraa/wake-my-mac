# Wake My Mac web

Marketing site for Wake My Mac, intentionally kept separate from the Swift package. The root `Package.swift` targets only `Sources/HoldMyLid`, so this directory is not compiled or copied into the macOS application bundle.

## Local development

```bash
bun install
bun run dev
```

## Production build

```bash
bun run build
bun run start
```
