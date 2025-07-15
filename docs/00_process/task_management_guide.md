# Task Management Guide

## 🎯 **Mục Đích**
Quy trình làm việc chuẩn cho **HOW to work** từ planning đến completion, đảm bảo:
- **Code quality**: Consistent và maintainable
- **Documentation**: Always up-to-date
- **Progress tracking**: Transparent và accurate
- **Knowledge sharing**: Lessons learned được capture

> 🔗 **Content Integration**: This guide focuses on **workflow processes**. For **content maintenance strategy** (WHAT to document), see [Documentation Maintenance Guide](documentation_maintenance_guide.md)

## 🔄 **Task Lifecycle Overview**

```
📋 BEFORE Task    →    💻 DURING Task    →    ✅ AFTER Task
├── Planning           ├── Development        ├── Review & Update
├── Setup              ├── Documentation      ├── Knowledge Capture
└── Preparation        └── Progress Tracking  └── Cleanup
```

---

## 📋 **BEFORE Task - Planning & Setup**

### **1. Task Definition & Planning**
#### **Task Analysis**
- [ ] **Define** clear task objective và success criteria
- [ ] **Estimate** effort (Small: <2h, Medium: 2-8h, Large: >8h)
- [ ] **Identify** dependencies và blockers
- [ ] **Check** if task aligns với current sprint goals

#### **Technical Planning**
- [ ] **Review** related code areas cần modify
- [ ] **Identify** potential architecture impacts
- [ ] **Plan** testing approach
- [ ] **Consider** performance implications

### **2. Environment Setup**
#### **Development Environment**
- [ ] **Pull** latest code từ main branch
- [ ] **Create** feature branch với naming convention: `feature/task-description`
- [ ] **Verify** development environment working
- [ ] **Run** existing tests để ensure baseline

#### **Documentation Setup**
- [ ] **Check** current documentation related to task area
- [ ] **Identify** docs sẽ cần update
- [ ] **Plan** new documentation nếu cần

### **3. Context Preparation**
#### **AI Context Setup**
- [ ] **Attach** relevant context files to AI conversation
- [ ] **Review** previous related tasks/decisions
- [ ] **Prepare** specific questions for AI assistance

#### **Knowledge Review**
- [ ] **Read** related code và documentation
- [ ] **Understand** existing patterns và conventions
- [ ] **Note** any unclear areas cần clarification

---

## 💻 **DURING Task - Active Development**

### **1. Development Workflow**
#### **Code Development**
- [ ] **Follow** established coding standards (.cursorrules)
- [ ] **Write** code incrementally với frequent commits
- [ ] **Use** descriptive commit messages
- [ ] **Test** changes locally throughout development
- [ ] **CRITICAL**: If creating new files, **add them to Xcode project target immediately** (drag & drop from Finder to Xcode). This prevents build failures
  > 📖 **Lý do & Cách làm**: [Xem chi tiết tại đây](../0_knowledge/02_swift_app_dev/02_swift_app_dev.md#phần-5-xử-lý-lỗi-build-phổ-biến---file-not-found)

#### **Documentation Updates**
- [ ] **Update** inline code comments for complex logic
- [ ] **Modify** relevant documentation files as code changes
- [ ] **Add** new docs for new features/components
- [ ] **Keep** documentation in sync với code changes

### **2. Progress Tracking**
#### **Daily Updates**
**Daily Documentation Requirements** (Quick checklist):
- Update `current_status.md` with progress
- Update sprint plan with task status  
- Document significant decisions made
- Record blockers encountered

> 📖 **Detailed content strategy**: [Documentation Maintenance Guide](documentation_maintenance_guide.md#daily-after-each-development-session)  
> 📖 **Checklist templates**: [Checklist System Guide](checklist_system_guide.md#working-checklist-templates)

- [ ] **Update** `docs/00_context/current_status.md` với progress
- [ ] **Log** significant decisions made
- [ ] **Note** any blockers encountered
- [ ] **Record** time spent on task

#### **Session Documentation**
- [ ] **Capture** key learnings từ each coding session
- [ ] **Document** any architecture decisions made
- [ ] **Record** problems solved và solutions used
- [ ] **Note** areas needing future attention

### **3. Quality Assurance**
#### **Code Quality**
- [ ] **Review** code for adherence to standards
- [ ] **Run** linters và fix issues
- [ ] **Ensure** proper error handling
- [ ] **Verify** performance considerations

#### **Testing**
- [ ] **Write** unit tests for new functionality
- [ ] **Run** full test suite
- [ ] **Test** edge cases và error scenarios
- [ ] **Verify** integration với existing features
- [ ] **CRITICAL**: Khi test trên thiết bị thật, tuân thủ theo **[Quy trình Build & Deploy chính thức](../02_development/ios_app_development_guide.md#phần-7-quy-trình-build-run-test-official)** để đảm bảo bạn đang chạy code mới nhất.

---

## ✅ **AFTER Task - Review & Update**

### **1. Sprint Completion Requirements (New - Based on Sprint 3 Experience)**

#### **Test Suite Validation (MANDATORY)**
- [ ] **Run complete test suite** on real device using verified commands
- [ ] **Achieve 100% test pass rate** - no exceptions allowed
- [ ] **Document test results** with exact pass/fail counts
- [ ] **Fix all failing tests** before sprint can be marked complete
- [ ] **Update test suite** if new features added during sprint

**Verified Test Commands (iOS)**:
```bash
# 1. Clean build cache first
cd ios
xcodebuild clean -project OpenChatbot.xcodeproj -scheme OpenChatbot

# 2. Run complete test suite on simulator
xcodebuild test -project OpenChatbot.xcodeproj \
    -scheme OpenChatbot \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    | tee test_results.log

# 3. For real device testing (when device connected)
# First get device ID: xcrun devicectl list devices
xcodebuild test -project OpenChatbot.xcodeproj \
    -scheme OpenChatbot \
    -destination 'id=<DEVICE_ID>' \
    | tee device_test_results.log
```

#### **Sprint Documentation Updates**
- [ ] **Update sprint plan** with completion status and final metrics
- [ ] **Update current status** to reflect sprint completion and next phase
- [ ] **Update roadmap** to mark phase complete with actual achievements
- [ ] **Create sprint retrospective** document capturing lessons learned

### **2. Commit Message Standards (Updated)**

#### **Format Requirements**
**Template**: `<type>: <concise description>`

**Types**:
- `feat`: New feature implementation
- `fix`: Bug fixes and issue resolution
- `test`: Test suite updates and fixes
- `docs`: Documentation updates
- `refactor`: Code restructuring without behavior change
- `style`: Code formatting and style improvements
- `build`: Build system and dependency updates

**Examples**:
```bash
# Good commit messages (concise, informative, no emoji)
feat: implement ConversationSummaryMemory with AI-powered compression
fix: resolve token window management overflow in GPT-4 contexts
test: add comprehensive integration tests for memory system
docs: update sprint 3 plan with completion status and metrics
refactor: consolidate memory service interfaces for better maintainability

# Bad commit messages (avoid these)
fix: bug fix 🐛
update: stuff
test: tests
docs: 📝 update docs
```

#### **Commit Content Requirements**
- [ ] **Include context** - what was changed and why
- [ ] **Be specific** - mention components/files affected when relevant
- [ ] **Keep concise** - one line preferred, max 72 characters
- [ ] **No emoji** - maintain professional standard
- [ ] **Present tense** - "add feature" not "added feature"

### **3. Build and Deploy Commands (Verified)**

#### **iOS Development Commands**
Based on Sprint 3 experience, these commands are verified to work:

**Development Build (Simulator)**:
```bash
# Using SweetPad in Cursor (preferred for development)
# 1. Cmd+Shift+P → "SweetPad: Clean"
# 2. Cmd+Shift+P → "SweetPad: Build & Run"
# 3. Select iPhone 16 simulator

# Command line alternative
cd ios
xcodebuild -project OpenChatbot.xcodeproj \
    -scheme OpenChatbot \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    build
```

**Production Build (Real Device)**:
```bash
# Step 1: Clean build cache
cd ios
xcodebuild clean -project OpenChatbot.xcodeproj -scheme OpenChatbot

# Step 2: Build for specific device
# Get device ID first: xcrun devicectl list devices
xcodebuild -project OpenChatbot.xcodeproj \
    -scheme OpenChatbot \
    -destination 'id=<DEVICE_ID>' \
    build

# Step 3: Install on device
xcrun devicectl device install app \
    --device <DEVICE_ID> \
    <PATH_TO_APP_BUNDLE>
```

**Code Quality Checks**:
```bash
# Run all quality checks
./scripts/format.sh

# Individual commands
swiftlint lint --strict
swiftformat --lint .
```

### **4. Quality Assurance Checklist**

#### **Before Sprint Completion**
- [ ] All planned features implemented and working
- [ ] Test suite updated for new functionality
- [ ] 100% test pass rate achieved on both simulator and real device
- [ ] Code quality standards met (SwiftLint + SwiftFormat)
- [ ] Documentation updated to reflect current state
- [ ] No critical bugs or crashes in production scenarios

#### **Sprint Metrics Documentation**
- [ ] **Test Coverage**: X/X tests passed (target: 100%)
- [ ] **Performance**: Key metrics within acceptable ranges
- [ ] **Build Status**: Clean builds on all target platforms
- [ ] **Code Quality**: No lint errors, consistent formatting
- [ ] **Documentation**: All guides updated and accurate

### **5. Knowledge Capture**
#### **Sprint Retrospective Document**
- [ ] **Create** retrospective document với lessons learned
- [ ] **Capture** what worked well và what needs improvement
- [ ] **Document** technical challenges và solutions found
- [ ] **Record** process improvements for next sprint
- [ ] **Update** best practices based on experience

#### **Update Project Documentation**
> 📖 **Content maintenance strategy**: [Documentation Maintenance Guide](documentation_maintenance_guide.md) - File-specific maintenance rules and schedules

- [ ] **Technical guides** updated với new findings
- [ ] **Architecture decisions** documented
- [ ] **Performance optimizations** recorded
- [ ] **Integration patterns** captured

#### **Team Knowledge Sharing**
- [ ] **Share** key insights với team
- [ ] **Update** development guides based on experience
- [ ] **Document** common issues và solutions
- [ ] **Create** troubleshooting entries for future reference

### **6. Sprint Completion Validation**

#### **Final Sprint Checklist (MANDATORY)**
This checklist must be completed before marking any sprint as complete:

**Technical Validation**:
- [ ] ✅ **100% test pass rate** verified on real device
- [ ] ✅ **All build commands working** with verified procedures
- [ ] ✅ **Code quality standards met** (no lint errors)
- [ ] ✅ **Performance benchmarks achieved** for new features
- [ ] ✅ **No critical bugs** in production scenarios

**Documentation Validation**:
- [ ] ✅ **Sprint plan updated** with completion status and metrics
- [ ] ✅ **Current status document updated** to reflect new phase
- [ ] ✅ **Roadmap updated** with actual achievements vs planned
- [ ] ✅ **All technical guides updated** for new features
- [ ] ✅ **Sprint retrospective created** with lessons learned

**Process Validation**:
- [ ] ✅ **All commits follow** standardized message format
- [ ] ✅ **All changes pushed** to remote repository
- [ ] ✅ **Branch merge completed** if applicable
- [ ] ✅ **Next sprint preparation** started based on retrospective

**Success Criteria Met**:
- [ ] ✅ **All sprint goals achieved** or justified alternatives documented
- [ ] ✅ **Quality standards maintained** throughout development
- [ ] ✅ **Team learnings captured** for continuous improvement
- [ ] ✅ **Foundation prepared** for next sprint

#### **Sprint Completion Metrics Template**
Document these metrics for every completed sprint:

```markdown
# Sprint X Completion Report

## Achievement Summary
- **Test Results**: X/X tests passed (100% target achieved)
- **Features Delivered**: X/X planned features completed
- **Code Quality**: 0 lint errors, consistent formatting maintained
- **Performance**: All benchmarks within acceptable ranges
- **Documentation**: All guides updated and verified

## Challenges and Solutions
- **Challenge 1**: [Description] → **Solution**: [Approach taken]
- **Challenge 2**: [Description] → **Solution**: [Approach taken]

## Process Improvements Identified
- **Improvement 1**: [What we learned]
- **Improvement 2**: [Process adjustment for next sprint]

## Next Sprint Readiness
- **Foundation**: ✅ Ready for [next phase]
- **Blockers**: None identified / [List any blockers]
- **Team Capacity**: [Assessment for next sprint]
```

---

## 🚨 **Common Pitfalls & Solutions**

### **Test Suite Management**
**Problem**: Tests passing locally but failing in CI/different environment
**Solution**: Always test on multiple environments including real devices before sprint completion

**Problem**: New features added without corresponding test updates
**Solution**: Test suite updates are MANDATORY part of feature completion, not optional

### **Commit Message Quality**
**Problem**: Vague commit messages make debugging difficult later
**Solution**: Include specific component names and clear description of changes

**Problem**: Using emoji or casual language in commits
**Solution**: Maintain professional standards for long-term maintainability

### **Sprint Completion Rush**
**Problem**: Rushing to mark sprint complete without proper validation
**Solution**: Follow the mandatory completion checklist - no exceptions

**Problem**: Skipping documentation updates to "save time"
**Solution**: Documentation debt always costs more time later than updating it immediately

### **Build and Deploy Issues**
**Problem**: "It works on my machine" but fails for others
**Solution**: Use verified command sequences and test on clean environments

**Problem**: Inconsistent build procedures across team members
**Solution**: Standardize on documented, verified command procedures

---

## 🔗 **Integration với Other Processes**

### **Documentation Maintenance**
> 📖 **Full documentation process**: [Documentation Maintenance Guide](documentation_maintenance_guide.md)

**Task workflow integrates với**:
- Daily documentation updates
- Weekly quality reviews
- Monthly strategic reviews

### **Sprint Planning**
> 📖 **Sprint planning process**: [Sprint Planning](03_implementation/sprint_planning/) (when available)

**Task workflow supports**:
- Sprint goal alignment
- Velocity tracking
- Retrospective insights

### **Code Review Process**
**Task workflow includes**:
- Self-review checklist
- Documentation review
- Knowledge sharing requirements

---

## 🎯 **Success Metrics**

### **Task Completion Quality**
- **Code quality**: No major issues in review
- **Documentation**: All related docs updated
- **Testing**: Full test coverage for changes
- **Knowledge**: Lessons learned captured

### **Process Efficiency**
- **Planning accuracy**: Estimates vs actual time
- **Scope stability**: Minimal scope changes
- **Rework rate**: Low number of follow-up fixes
- **Knowledge sharing**: Insights documented và shared

### **Team Alignment**
- **Consistency**: All team members follow same process
- **Transparency**: Progress visible to all stakeholders
- **Continuous improvement**: Process evolves based on feedback

---

## 🔄 **Process Evolution**

### **Weekly Review Questions**
1. **Efficiency**: Are task workflows smooth và efficient?
2. **Quality**: Are we maintaining code và documentation quality?
3. **Learning**: Are we capturing và sharing knowledge effectively?
4. **Alignment**: Are tasks aligned với project goals?

### **Monthly Optimization**
- **Analyze** task completion metrics
- **Identify** bottlenecks trong workflow
- **Update** templates based on experience
- **Refine** integration với other processes

---

*This guide evolves with team experience và project needs. Update based on retrospective feedback.* 