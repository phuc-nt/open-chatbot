# Feature Backlog - iOS Chatbot

## 🎯 MVP Features (Phase 1)

### P0 - Critical (Must Have)
| Feature | Effort | Dependencies | Status | Notes |
|---------|--------|--------------|---------|-------|
| API Key Management | 3d | - | 🟡 Planned | iOS Keychain integration |
| Basic Chat Interface | 5d | API Key Mgmt | 🟡 Planned | SwiftUI chat UI |
| OpenRouter Integration | 4d | API Key Mgmt | 🟡 Planned | REST API calls |
| Streaming Response | 3d | OpenRouter | 🟡 Planned | WebSocket/SSE |
| Conversation Storage | 4d | - | 🟡 Planned | Core Data models |
| Message History | 2d | Conv Storage | 🟡 Planned | List view with search |

### P1 - Important (Should Have)
| Feature | Effort | Dependencies | Status | Notes |
|---------|--------|--------------|---------|-------|
| PDF Upload | 5d | - | 🟡 Planned | PDFKit integration |
| Image Upload + OCR | 4d | - | 🟡 Planned | Vision framework |
| Markdown Rendering | 3d | - | 🟡 Planned | Swift package |
| Syntax Highlighting | 2d | Markdown | 🟡 Planned | Code blocks |
| Dark Mode Support | 2d | - | 🟡 Planned | SwiftUI themes |
| Export Conversations | 3d | - | 🟡 Planned | PDF/text export |

### P2 - Nice to Have
| Feature | Effort | Dependencies | Status | Notes |
|---------|--------|--------------|---------|-------|
| Multiple API Keys | 2d | API Key Mgmt | 🟡 Planned | Provider switching |
| Cost Tracking | 4d | API Integration | 🟡 Planned | Token usage monitor |
| Conversation Folders | 3d | Conv Storage | 🟡 Planned | Organization |
| iCloud Sync | 5d | Core Data | 🟡 Planned | CloudKit |

## 🚀 V2.0 Features (Phase 2)

### P0 - Critical
| Feature | Effort | Dependencies | Status | Notes |
|---------|--------|--------------|---------|-------|
| RAG System | 8d | PDF Upload | 🔴 Future | Vector embeddings |
| Custom Assistants | 5d | - | 🔴 Future | System prompts |
| Web Search Integration | 6d | - | 🔴 Future | Search API |
| YouTube Analysis | 4d | Web Search | 🔴 Future | Transcript extraction |

### P1 - Important
| Feature | Effort | Dependencies | Status | Notes |
|---------|--------|--------------|---------|-------|
| Advanced Export | 3d | Export | 🔴 Future | Better formatting |
| Batch File Processing | 4d | File Upload | 🔴 Future | Multiple files |
| Template Prompts | 2d | Custom Assistants | 🔴 Future | Pre-made prompts |
| Performance Optimization | 5d | - | 🔴 Future | Memory, speed |

## 🎯 V3.0 Features (Phase 3)

### P0 - Critical
| Feature | Effort | Dependencies | Status | Notes |
|---------|--------|--------------|---------|-------|
| Advanced Analytics | 6d | Cost Tracking | 🔴 Future | Usage insights |
| Multi-device Sync | 4d | iCloud Sync | 🔴 Future | Real-time sync |
| Team Features | 8d | - | 🔴 Future | Sharing, collaboration |

## 📊 Status Legend
- 🟢 **Completed** - Feature is done and tested
- 🟡 **Planned** - In current sprint/phase
- 🔴 **Future** - Planned for later phases
- ⚫ **Blocked** - Waiting on dependencies
- 🔵 **In Progress** - Currently being developed

## 🔄 Effort Estimation
- **1d** = 1 day of focused work
- **Estimates include**: Design, coding, testing, documentation
- **Buffer**: Add 20% for unexpected issues

## 📝 Notes
- Priority can change based on user feedback
- Effort estimates will be refined as we learn more
- Dependencies must be completed before starting dependent features

---
*Last updated: [Date]*
*Next review: [Date]* 