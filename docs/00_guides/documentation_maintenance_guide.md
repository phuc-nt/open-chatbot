# Documentation Maintenance Guide

## 🎯 **Mục Đích**
Hướng dẫn maintain toàn bộ documentation system để đảm bảo:
- **Accuracy**: Thông tin luôn up-to-date
- **Consistency**: Format và style thống nhất
- **Efficiency**: No duplication, clear links
- **Usability**: Easy to find và understand

## 📁 **Documentation Structure Overview**
```
docs/
├── documentation_maintenance_guide.md  # 📋 This file
├── README.md                          # 📖 Docs overview
├── 00_context/                        # 🎯 Quick context
├── 01_preparation/                     # 📋 Planning docs
├── 02_development/                     # 🛠️ Setup & architecture
├── 03_implementation/                  # 💻 Development docs
└── 04_troubleshooting/                 # 🔧 Issues & releases
```

## 🔄 **Maintenance Schedule**

> 📖 **Task workflow integration**: [Task Management Guide](task_management_guide.md) - Complete task workflow including documentation steps
> 📖 **Working checklists**: [Checklist System Guide](checklist_system_guide.md) - How to use checklists in practice

### **Daily (After Each Development Session)**
#### Context Files (00_context/)
- [ ] **Update** `current_status.md` với latest progress
- [ ] **Verify** links trong context files vẫn accurate
- [ ] **Check** current_status.md không exceed 2 pages

#### Implementation Docs (03_implementation/)
- [ ] **Update** `progress_tracker.md` với daily progress
- [ ] **Add** coding session notes nếu có significant learnings
- [ ] **Update** sprint status nếu có task completion

### **Weekly (End of Sprint)**
#### All Folders Review
- [ ] **Review** tất cả README files cho duplication
- [ ] **Validate** all internal links work correctly
- [ ] **Check** file sizes - context files max 2 pages
- [ ] **Update** project_roadmap.md với actual vs planned progress

#### Quality Checks
- [ ] **Scan** for duplicate content across files
- [ ] **Verify** consistent formatting (markdown style)
- [ ] **Ensure** each doc has clear purpose và audience
- [ ] **Check** date stamps are current

### **Monthly (Major Milestone)**
#### Strategic Review
- [ ] **Evaluate** documentation structure effectiveness
- [ ] **Archive** outdated documents
- [ ] **Reorganize** if folder structure needs improvement
- [ ] **Update** maintenance guide based on learnings

#### Content Audit
- [ ] **Review** all context files for relevance
- [ ] **Update** project_overview.md nếu scope changed
- [ ] **Consolidate** similar documents nếu có
- [ ] **Create** missing documentation identified

## 📋 **Folder-Specific Guidelines**

### **00_context/ - Context Files**
**Purpose**: Quick onboarding cho AI và developers

**Maintenance Rules**:
- **Max length**: 2 pages per file
- **Update frequency**: current_status.md daily, others major changes only
- **Link strategy**: Heavy linking to detailed docs
- **Content rule**: Summary + pointers, no detailed info

**Quality Checklist**:
- [ ] Files load in <5 seconds reading time
- [ ] All links point to most relevant sections
- [ ] No duplicate content với detailed docs
- [ ] Reading guide reflects current structure

### **01_preparation/ - Planning Documents**
**Purpose**: Complete planning và requirements

**Maintenance Rules**:
- **Update frequency**: When requirements change
- **Version control**: Update version numbers trong SRS
- **Consistency**: Feature names consistent across all docs
- **Completeness**: All decisions documented với reasoning

**Quality Checklist**:
- [ ] SRS reflects current project scope
- [ ] Feature backlog priorities current
- [ ] Roadmap dates realistic based on progress
- [ ] Best practices updated với new learnings

### **02_development/ - Setup & Architecture**
**Purpose**: Technical setup và architectural decisions

**Maintenance Rules**:
- **Update frequency**: When tools/architecture change
- **Accuracy**: Setup instructions work on fresh environment
- **Versioning**: Include version numbers cho tools
- **Testing**: Periodically test setup instructions

**Quality Checklist**:
- [ ] Dev environment guide works end-to-end
- [ ] Tool versions current và compatible
- [ ] Architecture decisions still valid
- [ ] No broken installation links

### **03_implementation/ - Development Documentation**
**Purpose**: Active development tracking và coding docs

**Maintenance Rules**:
- **Update frequency**: Daily progress, weekly summaries
- **Organization**: Archive completed sprint docs
- **Metrics**: Track velocity và quality metrics
- [ ] Session notes capture key learnings

**Quality Checklist**:
- [ ] Progress tracker reflects actual status
- [ ] Sprint docs archived when complete
- [ ] Coding sessions documented với outcomes
- [ ] Architecture docs updated với code changes

### **04_troubleshooting/ - Issues & Releases**
**Purpose**: Problem solving và release management

**Maintenance Rules**:
- **Update frequency**: When issues arise/resolved
- **Resolution tracking**: Document solutions, not just problems
- **Knowledge sharing**: Make solutions discoverable
- **Release notes**: Keep detailed changelog

**Quality Checklist**:
- [ ] Known issues have status updates
- [ ] Solutions documented with steps
- [ ] Release notes complete và accurate
- [ ] Debugging guides current

## 🔗 **Link Management**

### **Link Validation Rules**
- **Internal links**: Use relative paths
- **External links**: Check monthly for validity
- **Context links**: Always point to most relevant section
- **Broken links**: Fix immediately when discovered

### **Link Format Standards**
```markdown
# Internal links
> 📖 **Description**: [Title](../folder/file.md)

# External links  
[Title](https://example.com)

# Section links
[Section Title](../folder/file.md#section-anchor)
```

## 📏 **Content Standards**

### **File Naming**
- **Lowercase**: Use lowercase với hyphens
- **Descriptive**: Clear purpose from filename
- **Consistent**: Similar docs use similar naming pattern
- **No spaces**: Use hyphens instead of spaces

### **Markdown Style**
- **Headers**: Use ## for main sections, ### for subsections
- **Lists**: Use - for unordered, numbers for ordered
- **Code**: Use ``` for code blocks, ` for inline code
- **Emphasis**: **Bold** for important, *italic* for emphasis

### **Content Organization**
- **Purpose statement**: Every doc starts với purpose
- **Audience**: Clear who should read this
- **Update info**: Last updated date at bottom
- **Table of contents**: For docs >3 pages

## 🚨 **Red Flags to Watch**

### **Content Issues**
- [ ] **Duplicate information** across multiple files
- [ ] **Outdated screenshots** or version numbers
- [ ] **Broken internal links** between documents
- [ ] **Inconsistent terminology** across docs

### **Structure Issues**
- [ ] **Files too long** (context files >2 pages)
- [ ] **Missing README** files in folders
- [ ] **Unclear file purposes** or audiences
- [ ] **Poor folder organization** for current needs

### **Maintenance Issues**
- [ ] **Outdated last-updated** dates (>1 month old)
- [ ] **Missing progress updates** for active development
- [ ] **Stale links** to external resources
- [ ] **Inconsistent formatting** across similar docs

## 🎯 **Success Metrics**

### **Efficiency Metrics**
- **Onboarding time**: New developer ready in <1 hour
- **AI context time**: AI productive in <3 minutes
- **Find information**: Any info findable in <2 minutes
- **Link accuracy**: >95% internal links work

### **Quality Metrics**
- **Content freshness**: All docs updated within relevance period
- **Consistency**: No duplicate information
- **Completeness**: All major decisions documented
- **Usability**: Clear purpose và audience for each doc

## 🔄 **Continuous Improvement**

### **Monthly Review Questions**
1. **Structure**: Is current folder organization still optimal?
2. **Content**: Are we duplicating information unnecessarily?
3. **Process**: Is maintenance workflow efficient?
4. **Tools**: Do we need better tools for documentation?

### **Quarterly Optimization**
- **Archive**: Move outdated docs to archive folder
- **Consolidate**: Merge similar or redundant documents
- **Restructure**: Reorganize if usage patterns changed
- **Automate**: Identify manual tasks that could be automated

---
*This guide evolves with our documentation needs. Update quarterly based on actual usage patterns.* 