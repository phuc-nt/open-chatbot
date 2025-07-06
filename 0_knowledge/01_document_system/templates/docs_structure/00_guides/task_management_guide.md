# Task Management Guide - {{PROJECT_NAME}}

<!-- 
📝 HƯỚNG DẪN SỬ DỤNG TEMPLATE:
1. Điều chỉnh workflow cho phù hợp với team size và project complexity
2. Thay thế {{PLACEHOLDER}} bằng thông tin cụ thể
3. Có thể bỏ bớt bước nếu dự án nhỏ (1-2 người)
4. Tùy chỉnh tool sử dụng (GitHub Issues, Trello, Notion, v.v.)
-->

## 🎯 **Task Management Philosophy**
**Core Principle**: {{TASK_PHILOSOPHY}} <!-- Ví dụ: "One task at a time, document everything, AI as teammate" -->

**AI-Friendly Approach**: 
- Clear, written instructions
- Context-rich documentation  
- Structured progress tracking
- Consistent naming conventions

## 📋 **Task Lifecycle**

### **Phase 1: Task Creation** 
1. **Identify Need**: {{TASK_IDENTIFICATION}} <!-- Ví dụ: "From feature backlog or bug reports" -->
2. **Create Task File**: `{{TASK_LOCATION}}/task_{{TASK_ID}}.md` <!-- Ví dụ: "03_implementation/tasks/task_001.md" -->
3. **Use Template**: Copy from `{{TASK_TEMPLATE_PATH}}` <!-- Ví dụ: "00_guides/task_template.md" -->
4. **Set Priority**: {{PRIORITY_SYSTEM}} <!-- Ví dụ: "P0 (Critical), P1 (High), P2 (Medium), P3 (Low)" -->

### **Phase 2: Task Planning**
1. **Break Down**: Split into {{SUBTASK_SIZE}} subtasks <!-- Ví dụ: "2-4 hour" -->
2. **Define Acceptance Criteria**: Clear, testable requirements
3. **Identify Dependencies**: Link to prerequisite tasks
4. **Estimate Effort**: {{ESTIMATION_METHOD}} <!-- Ví dụ: "T-shirt sizes (S/M/L/XL)" -->

### **Phase 3: Task Execution**
1. **Update Status**: `pending` → `in_progress`
2. **Create Working Branch**: `{{BRANCH_NAMING}}` <!-- Ví dụ: "feature/task-001-user-auth" -->
3. **Daily Updates**: Update progress in task file
4. **Document Decisions**: Log important choices made

### **Phase 4: Task Completion**
1. **Self-Review**: Check acceptance criteria
2. **Update Documentation**: If needed
3. **Create PR/MR**: {{PR_PROCESS}} <!-- Ví dụ: "Follow PR template, request review" -->
4. **Update Status**: `in_progress` → `completed`
5. **Archive Task**: Move to `{{COMPLETED_LOCATION}}` <!-- Ví dụ: "03_implementation/completed/" -->

## 📂 **File Organization**

### **Active Tasks**
```
{{ACTIVE_TASKS_PATH}}/
├── task_001_{{TASK_NAME}}.md
├── task_002_{{TASK_NAME}}.md
└── README.md  # Task index
```

### **Completed Tasks**
```
{{COMPLETED_TASKS_PATH}}/
├── {{YEAR}}/
│   ├── {{MONTH}}/
│   │   ├── task_001_{{TASK_NAME}}.md
│   │   └── task_002_{{TASK_NAME}}.md
└── README.md  # Archive index
```

## 🏷️ **Naming Conventions**

### **Task Files**
- Format: `task_{{ID}}_{{SHORT_DESCRIPTION}}.md`
- Example: `task_001_user_authentication.md`
- ID: 3-digit zero-padded number

### **Git Branches**
- Format: `{{TYPE}}/task-{{ID}}-{{DESCRIPTION}}`
- Types: `feature`, `bugfix`, `hotfix`, `refactor`
- Example: `feature/task-001-user-auth`

### **Commit Messages**
- Format: `{{TYPE}}(task-{{ID}}): {{DESCRIPTION}}`
- Example: `feat(task-001): add user authentication service`

## 📊 **Progress Tracking**

### **Daily Standup Format**
```markdown
## Daily Update - {{DATE}}

### Yesterday
- {{COMPLETED_ITEM_1}}
- {{COMPLETED_ITEM_2}}

### Today  
- {{PLANNED_ITEM_1}}
- {{PLANNED_ITEM_2}}

### Blockers
- {{BLOCKER_1}} (if any)
```

### **Weekly Review**
1. **Completed Tasks**: Count and celebrate
2. **Velocity**: Compare planned vs actual
3. **Blockers**: Identify patterns
4. **Process**: What can be improved?

## 🤖 **AI Collaboration Guidelines**

### **When Starting a Task**
1. **Share Context**: Give AI the task file
2. **Explain Goal**: What you want to achieve
3. **Set Boundaries**: What AI should/shouldn't do
4. **Request Format**: How you want output structured

### **During Task Execution**
1. **Regular Updates**: Keep AI informed of progress
2. **Ask for Help**: When stuck or need ideas
3. **Document Decisions**: AI suggestions and your choices
4. **Code Reviews**: Have AI review your work

### **Task Completion**
1. **Summary**: Ask AI to summarize what was done
2. **Lessons Learned**: What went well/poorly
3. **Next Steps**: Preparation for follow-up tasks

## 🔄 **Integration with Other Processes**

### **Feature Development**
- Tasks created from `{{FEATURE_BACKLOG_PATH}}`
- Link back to feature requirements
- Update feature status when tasks complete

### **Bug Fixes**
- Tasks created from bug reports
- Include reproduction steps
- Test fix thoroughly before closing

### **Documentation**
- Update relevant docs during task execution
- Create new docs if needed
- Review doc accuracy after completion

## 📈 **Metrics & KPIs**

### **Track These Metrics**
- **Completion Rate**: {{COMPLETION_TARGET}}% <!-- Ví dụ: "85%" -->
- **Cycle Time**: {{CYCLE_TIME_TARGET}} <!-- Ví dụ: "3-5 days average" -->
- **Blocker Frequency**: {{BLOCKER_TARGET}} <!-- Ví dụ: "<10% of tasks" -->
- **Rework Rate**: {{REWORK_TARGET}} <!-- Ví dụ: "<15% of tasks" -->

### **Review Frequency**
- **Daily**: Individual task progress
- **Weekly**: Team velocity and blockers  
- **Monthly**: Process improvements

## 🛠️ **Tools & Templates**

### **Required Tools**
- **Task Tracking**: {{TASK_TOOL}} <!-- Ví dụ: "GitHub Issues + local markdown files" -->
- **Code Management**: {{CODE_TOOL}} <!-- Ví dụ: "Git + GitHub" -->
- **Documentation**: {{DOC_TOOL}} <!-- Ví dụ: "Markdown files in repo" -->
- **Communication**: {{COMM_TOOL}} <!-- Ví dụ: "Slack + GitHub comments" -->

### **Templates Available**
- [Task Template](task_template.md)
- [Daily Update Template](daily_update_template.md)
- [Weekly Review Template](weekly_review_template.md)
- [Bug Report Template](bug_report_template.md)

---

## 🚀 **Quick Start Checklist**

For new team members:
- [ ] Read this guide completely
- [ ] Set up required tools
- [ ] Create your first task using template
- [ ] Practice the workflow with a small task
- [ ] Join team standup rhythm
- [ ] Ask questions when unclear

*Remember: The process serves the project, not the other way around. Adapt as needed!*

---
*Last updated: {{LAST_UPDATED}}* 