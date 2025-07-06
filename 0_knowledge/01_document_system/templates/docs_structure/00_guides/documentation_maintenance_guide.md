# Documentation Maintenance Guide - {{PROJECT_NAME}}

<!-- 
📝 HƯỚNG DẪN SỬ DỤNG TEMPLATE:
1. Điều chỉnh quy tắc cho phù hợp với team culture
2. Thay thế {{PLACEHOLDER}} bằng thông tin cụ thể
3. Có thể thêm/bớt rules tùy theo project complexity
4. Đảm bảo AI đọc file này trước khi tạo/cập nhật docs
-->

## 🎯 **Documentation Philosophy**

**Core Principle**: {{DOC_PHILOSOPHY}} <!-- Ví dụ: "Documentation is code - it should be accurate, up-to-date, and useful" -->

**AI-First Approach**: Tài liệu được viết để AI hiểu nhanh và chính xác, con người cũng dễ đọc.

## 📋 **Documentation Rules**

### **Rule 1: Single Source of Truth**
- **Mỗi thông tin chỉ xuất hiện ở 1 nơi**
- **Sử dụng links** thay vì copy-paste
- **Cập nhật tại nguồn** khi có thay đổi
- **Xóa duplicate content** ngay khi phát hiện

### **Rule 2: Context-Rich Content**
- **Luôn giải thích "Why"** trước "What" và "How"
- **Cung cấp background** cho decisions
- **Link tới related docs** để tạo context web
- **Sử dụng examples** thực tế từ project

### **Rule 3: Structured Information**
- **Sử dụng headings** có hierarchy rõ ràng
- **Bullet points** cho lists
- **Tables** cho comparisons
- **Code blocks** với syntax highlighting

### **Rule 4: Actionable Content**
- **Mỗi document phải có clear purpose**
- **Cung cấp next steps** cụ thể
- **Include checklists** khi có thể
- **Specify who does what** trong instructions

### **Rule 5: Maintenance Responsibility**
- **Author maintains** documents they create
- **Update immediately** when making changes
- **Review quarterly** for accuracy
- **Archive obsolete** documents

## 📝 **Writing Standards**

### **Language & Tone**
- **{{LANGUAGE}}** <!-- Ví dụ: "Vietnamese for team communication, English for technical terms" -->
- **{{TONE}}** <!-- Ví dụ: "Professional but friendly, direct and clear" -->
- **Avoid jargon** unless defined
- **Use active voice** where possible

### **Structure Templates**

#### **For Process Documents**
```markdown
# Title - {{PROJECT_NAME}}

## 🎯 Purpose
[Why this process exists]

## 📋 Steps
1. [Step 1 with details]
2. [Step 2 with details]

## 🔧 Tools Required
- [Tool 1]
- [Tool 2]

## 📊 Success Metrics
- [Metric 1]
- [Metric 2]

## 🛠️ Troubleshooting
[Common issues and solutions]
```

#### **For Technical Documents**
```markdown
# Component Name - {{PROJECT_NAME}}

## 🎯 Overview
[What this component does]

## 🏗️ Architecture
[How it works]

## 📋 API/Interface
[How to use it]

## 🔧 Configuration
[Setup instructions]

## 📊 Monitoring
[How to track it]

## 🛠️ Troubleshooting
[Common issues]
```

### **Formatting Rules**

#### **Headers**
- **H1**: Document title only
- **H2**: Major sections
- **H3**: Subsections
- **H4**: Rarely used, only for deep nesting

#### **Lists**
- **Ordered lists**: For sequences/steps
- **Unordered lists**: For collections/options
- **Nested lists**: Max 3 levels deep

#### **Links**
- **Internal links**: `[Text](relative/path.md)`
- **External links**: `[Text](https://example.com)`
- **Section links**: `[Text](#section-name)`

#### **Code & Commands**
- **Inline code**: `backticks` for short snippets
- **Code blocks**: ```language for longer code
- **Commands**: Always show expected output

#### **Emphasis**
- **Bold**: For important terms, UI elements
- **Italic**: For emphasis, foreign terms
- **Underline**: Avoid, use bold instead

## 🔄 **Update Process**

### **When to Update**
1. **Immediately**: When making code changes that affect docs
2. **Weekly**: Review current_status.md
3. **Monthly**: Review process documents
4. **Quarterly**: Full documentation audit

### **How to Update**
1. **Edit in place**: Don't create new versions
2. **Update timestamps**: Add "Last updated" footer
3. **Check links**: Ensure all references still work
4. **Validate structure**: Follow templates
5. **Test with AI**: Ensure AI can understand updates

### **Review Process**
1. **Self-review**: Check your own changes
2. **Peer review**: For major updates
3. **AI review**: Test understanding with AI
4. **Stakeholder review**: For process changes

## 🤖 **AI Collaboration Guidelines**

### **Before AI Creates Documents**
1. **AI must read this guide first**
2. **AI should ask clarifying questions**
3. **AI should reference existing docs**
4. **AI should follow established patterns**

### **AI Document Creation Rules**
- **Use established templates**
- **Follow naming conventions**
- **Include proper metadata**
- **Link to related documents**
- **Add placeholder for future updates**

### **AI Update Guidelines**
- **Preserve document structure**
- **Maintain consistent tone**
- **Update timestamps**
- **Check for broken links**
- **Validate against templates**

## 📂 **File Organization**

### **Naming Conventions**
- **Files**: `snake_case.md`
- **Folders**: `01_descriptive_name`
- **Images**: `component_name_screenshot.png`
- **Documents**: `document_type_version.md`

### **Folder Structure**
```
docs/
├── README.md                    # Entry point
├── 00_context/                  # Long-term context
├── 00_guides/                   # Process guides
├── 01_preparation/              # Planning docs
├── 02_development/              # Dev setup
├── 03_implementation/           # Active work
├── 04_troubleshooting/          # Issue resolution
└── assets/                      # Images, diagrams
```

### **Document Lifecycle**
1. **Draft**: In progress, may be incomplete
2. **Review**: Complete, under review
3. **Active**: Approved, in use
4. **Archive**: Obsolete, moved to archive/

## 📊 **Quality Metrics**

### **Document Quality Checklist**
- [ ] **Purpose is clear** in first paragraph
- [ ] **Structure follows template**
- [ ] **All links work**
- [ ] **Code examples are tested**
- [ ] **Screenshots are current**
- [ ] **Spelling/grammar checked**
- [ ] **AI can understand content**

### **Documentation Health**
- **Coverage**: {{COVERAGE_TARGET}}% of features documented <!-- Ví dụ: "90%" -->
- **Freshness**: {{FRESHNESS_TARGET}}% updated in last 30 days <!-- Ví dụ: "80%" -->
- **Accuracy**: {{ACCURACY_TARGET}}% of links working <!-- Ví dụ: "95%" -->
- **Usability**: {{USABILITY_TARGET}} AI onboarding time <!-- Ví dụ: "<5 minutes" -->

## 🛠️ **Tools & Automation**

### **Required Tools**
- **Editor**: {{EDITOR_TOOL}} <!-- Ví dụ: "Cursor, VS Code, or any markdown editor" -->
- **Link Checker**: {{LINK_CHECKER}} <!-- Ví dụ: "markdown-link-check or manual verification" -->
- **Spell Check**: {{SPELL_CHECKER}} <!-- Ví dụ: "Built-in editor spell check" -->
- **Version Control**: {{VERSION_CONTROL}} <!-- Ví dụ: "Git with meaningful commit messages" -->

### **Automation Opportunities**
- **Link checking**: Automated in CI/CD
- **Spell checking**: Pre-commit hooks
- **Template validation**: Custom scripts
- **Freshness alerts**: Scheduled reminders

## 🚨 **Common Mistakes to Avoid**

### **Content Issues**
- **Outdated information**: Regular reviews prevent this
- **Broken links**: Check before committing
- **Unclear purpose**: Start with "Why this document exists"
- **Missing context**: Assume reader knows nothing

### **Structure Issues**
- **Inconsistent formatting**: Use templates
- **Deep nesting**: Keep hierarchies shallow
- **Wall of text**: Use bullets and headers
- **Missing navigation**: Include table of contents

### **Process Issues**
- **Forgetting to update**: Make it part of definition-of-done
- **Creating duplicates**: Search before creating
- **Ignoring templates**: Follow established patterns
- **No ownership**: Assign clear maintainers

## 🎯 **Success Criteria**

A well-maintained documentation system should:
- [ ] **Enable 5-minute AI onboarding**
- [ ] **Support new team member productivity in 30 minutes**
- [ ] **Eliminate "where do I find X?" questions**
- [ ] **Reduce context-switching time by 50%**
- [ ] **Maintain 95%+ accuracy**

---

## 📋 **Quick Reference**

### **Before Creating New Document**
1. Search existing docs
2. Read this guide
3. Choose appropriate template
4. Follow naming conventions
5. Plan update schedule

### **Before Updating Existing Document**
1. Read current version completely
2. Identify what's changing and why
3. Update related documents
4. Check all links
5. Test with AI if major changes

### **Before Archiving Document**
1. Confirm it's truly obsolete
2. Update all references
3. Move to archive folder
4. Add archive notice
5. Update indexes

---

*This guide is living documentation - update it as we learn!*

---
*Last updated: {{LAST_UPDATED}}*  
*Next review: {{NEXT_REVIEW_DATE}}* 