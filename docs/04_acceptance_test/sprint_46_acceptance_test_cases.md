# 📋 **Acceptance Test Cases - Sprint 4.6: Dual Chat Mode**
*Real Device Testing Guide cho Dual Chat Mode Implementation*

**Scope**: Dual Chat Mode System (RAG vs Full Context) với intelligent context management  
**Environment**: iPhone/iPad running iOS 17+  
**Testing Type**: End-to-end user scenarios on actual devices  
**Duration**: Each test case ~10-20 minutes  
**Prerequisites**: Sprint 4.1-4.5 features (Document Intelligence & RAG) working correctly

---

## 🎯 **Sprint 4.6: Dual Chat Mode System - Acceptance Tests**

### **AT-4.6.1: Context Size Analysis & Recommendations**
**Purpose**: Verify intelligent context size calculation và mode recommendations  
**Technology**: ContextSizeCalculator + DocumentContextManager  
**Priority**: P0 (Critical)

#### **Test Steps:**
1. **Setup Document Collection**:
   - Upload small document (≤10k characters): Short report.pdf
   - Upload medium document (20-50k characters): Technical manual.pdf  
   - Upload large document (≥100k characters): Complete specification.pdf
   - Verify all documents processed và visible in Documents tab

2. **Test Context Size Analysis**:
   - Navigate to Documents tab → Select small document
   - Tap document để open DocumentDetailView
   - **Expected**: Green indicator showing "Perfect for Full Context"
   - Check context analysis card shows character count và percentage

3. **Test Mode Recommendations**:
   - For small document: Should recommend "Full Context" mode
   - For medium document: Should show "Large" status và suggest "RAG for speed"
   - For large document: Should show "Excessive" status với "RAG Mode recommended"

4. **Test Real-time Context Updates**:
   - Go to Chat tab → Select multiple documents
   - Add small + medium documents
   - Verify combined context size updates in real-time
   - Add large document → Should show warning về exceeding limits

#### **Expected Results:**
- ✅ Context size calculated accurately for all document types
- ✅ Visual indicators match actual document sizes (Green/Yellow/Red)
- ✅ Mode recommendations align với context size thresholds
- ✅ Real-time updates when adding/removing documents
- ✅ Analysis completes within 100ms per document

#### **Failure Criteria:**
- ❌ Incorrect size calculations or recommendations
- ❌ UI indicators don't match actual document size
- ❌ Context analysis takes >1 second to compute

---

### **AT-4.6.2: ChatModeSelector Component Integration**
**Purpose**: Verify dual chat mode selection interface works correctly  
**Technology**: ChatModeSelector + DocumentContextManager integration  
**Priority**: P0 (Critical)

#### **Test Steps:**
1. **Access Mode Selector**:
   - Upload 2-3 documents of varying sizes
   - Go to Chat tab → Open document picker
   - Select documents → Verify ChatModeSelector appears
   - Check both "RAG Mode" và "Full Context" options visible

2. **Test Mode Selection UI**:
   - Tap "RAG Mode" → Verify selection highlight changes
   - Tap "Full Context" → Verify selection updates
   - Check mode descriptions show correctly:
     - RAG: "Search relevant information"  
     - Full Context: "Include complete document"

3. **Test Context-Aware Warnings**:
   - Select large document collection
   - Choose "Full Context" mode
   - **Expected**: Warning message appears about potential slowness
   - Warning should mention "Large document - may be slower"

4. **Test Processing Time Estimates**:
   - For RAG mode: Should show ~2-3 second estimate
   - For Full Context mode: Should show longer estimate based on document size
   - Verify estimates update when switching modes

#### **Expected Results:**
- ✅ Mode selector displays both options clearly
- ✅ Selection state updates immediately on tap
- ✅ Warnings appear for large documents in Full Context mode
- ✅ Processing time estimates are realistic và update correctly
- ✅ UI remains responsive during mode switching

---

### **AT-4.6.3: Enhanced DocumentPickerView Functionality**
**Purpose**: Verify context-aware document selection experience  
**Technology**: Enhanced DocumentPickerView với batch selection  
**Priority**: P1 (Important)

#### **Test Steps:**
1. **Test Context Status Display**:
   - Open Chat tab → Tap document picker
   - Verify each document shows size indicator badge
   - Check color coding: Green (optimal), Yellow (large), Red (excessive)
   - Verify document sizes display in readable format (15k, 2.1M chars)

2. **Test Intelligent Batch Selection**:
   - Tap "Select All" button
   - Verify only optimal/large documents selected (skips excessive ones)
   - Check progress bar shows combined context utilization
   - Verify percentage updates as documents added/removed

3. **Test Context Limit Warnings**:
   - Manually select documents until limit approached
   - Try to add document that would exceed limits
   - **Expected**: Warning indicator appears with orange/red coloring
   - Message should say "May exceed context limits"

4. **Test Real-time Progress Bar**:
   - Select documents one by one
   - Watch progress bar fill up in real-time
   - Verify percentage matches actual context utilization
   - Test bar color changes: Green → Yellow → Red as limit approached

#### **Expected Results:**
- ✅ All documents show accurate size indicators
- ✅ Batch selection intelligently avoids excessive documents
- ✅ Progress bar updates smoothly in real-time
- ✅ Warning system activates before limits exceeded
- ✅ UI performs well với 10+ documents loaded

---

### **AT-4.6.4: Full Context Mode Processing**
**Purpose**: Verify complete document content inclusion works correctly  
**Technology**: Enhanced ChatViewModel với Full Context processing  
**Priority**: P0 (Critical)

#### **Test Steps:**
1. **Setup Full Context Test**:
   - Upload detailed technical document (20-40k characters)
   - Go to Chat → Select document → Choose "Full Context" mode
   - Tap "Done" để apply document selection

2. **Test Full Context Query Processing**:
   - Ask comprehensive question: "Tóm tắt toàn bộ nội dung tài liệu này một cách chi tiết"
   - **Expected**: AI receives complete document content (not just excerpts)
   - Response should reference details from throughout entire document

3. **Test Full Context vs RAG Comparison**:
   - Same document, ask same question in RAG mode
   - Compare responses:
     - RAG: Should reference specific relevant sections
     - Full Context: Should provide comprehensive overview using entire document

4. **Test Context Size Validation**:
   - Try Full Context với very large document (>150k chars)
   - **Expected**: System should automatically fallback to RAG mode
   - User should see warning: "Document too large for Full Context mode"

5. **Test Performance với Full Context**:
   - Measure response time với Full Context mode
   - Should be 2-3x slower than RAG mode but still usable
   - Verify streaming still works smoothly

#### **Expected Results:**
- ✅ AI receives complete document content in Full Context mode
- ✅ Responses demonstrate access to entire document, not just excerpts
- ✅ Automatic fallback to RAG when document too large
- ✅ Performance remains acceptable (response starts within 5 seconds)
- ✅ Clear distinction between RAG và Full Context response quality

#### **Failure Criteria:**
- ❌ Full Context mode provides same responses as RAG mode
- ❌ No fallback mechanism for oversized documents
- ❌ Response time exceeds 10 seconds to start

---

### **AT-4.6.5: DocumentDetailView Enhanced Interface**
**Purpose**: Verify enhanced document detail experience với mode integration  
**Technology**: Enhanced DocumentDetailView với context analysis  
**Priority**: P1 (Important)

#### **Test Steps:**
1. **Test Context Analysis Card**:
   - Navigate to Documents tab → Select document
   - Verify "Context Analysis" section displays:
     - Document size in readable format
     - Context status với color indicator
     - Recommended mode based on size

2. **Test Chat Mode Selection Integration**:
   - In DocumentDetailView, locate "Chat Mode" section
   - Tap "Configure" để expand mode selector
   - Verify ChatModeSelector appears với current document context
   - Test mode selection updates trong expanded view

3. **Test Enhanced Chat Button**:
   - Check chat button shows selected mode: "Using RAG Mode" or "Using Full Context"
   - For optimal documents: Button should show green checkmark
   - For large documents: Button should show warning icon
   - Tap button → Should navigate to Chat với pre-configured mode

4. **Test Context-Aware Navigation**:
   - From DocumentDetailView, tap enhanced chat button
   - **Expected**: Navigates to Chat tab với:
     - Document already selected
     - Mode pre-configured based on selection
     - Context ready for immediate use

#### **Expected Results:**
- ✅ Context analysis displays accurate document information
- ✅ Mode selector integrates seamlessly trong detail view
- ✅ Chat button reflects current mode selection
- ✅ Navigation carries context information correctly
- ✅ UI updates smoothly when changing modes

---

### **AT-4.6.6: Multi-Document Context Management**
**Purpose**: Verify intelligent handling of multiple documents với different modes  
**Technology**: DocumentContextManager với combined document analysis  
**Priority**: P1 (Important)

#### **Test Steps:**
1. **Setup Multi-Document Scenario**:
   - Upload documents of different sizes:
     - Document A: Small (5k chars) - Optimal for Full Context
     - Document B: Medium (30k chars) - Large status
     - Document C: Large (120k chars) - Excessive status

2. **Test Combined Context Analysis**:
   - Select Document A + B → Check combined size calculation
   - **Expected**: Shows combined character count và updated status
   - Add Document C → Should show warning về exceeding limits

3. **Test Intelligent Mode Selection**:
   - A + B combination: Should still allow Full Context mode
   - A + B + C combination: Should force RAG mode với warning
   - Remove C: Should return to allowing Full Context

4. **Test Mode Behavior với Mixed Documents**:
   - Select optimal + large documents → Choose Full Context
   - **Expected**: System processes all documents in Full Context mode
   - Verify response demonstrates access to complete content from all documents

5. **Test Context Limit Enforcement**:
   - Try to add documents exceeding model's context window
   - System should prevent selection or show clear warnings
   - User should understand why certain combinations not allowed

#### **Expected Results:**
- ✅ Combined context size calculated accurately
- ✅ Mode availability updates based on total context size
- ✅ Intelligent warnings when approaching limits
- ✅ Multi-document Full Context processes all documents completely
- ✅ Clear feedback when document combinations not viable

---

### **AT-4.6.7: Cross-Feature Integration Testing**
**Purpose**: Verify dual chat mode integrates well với existing features  
**Technology**: Integration với Memory System, Document Management, API Services  
**Priority**: P1 (Important)

#### **Test Steps:**
1. **Test Memory System Integration**:
   - Have conversation in Full Context mode với Document A
   - Switch to RAG mode với Document B trong same conversation
   - Verify AI maintains conversation history while adapting to new mode
   - Ask: "Compare the two documents we discussed" → Should reference both

2. **Test Model Switching Integration**:
   - Start conversation với GPT-4 model trong Full Context mode
   - Switch to Claude model (higher context limit) trong Settings
   - Return to same document → Verify context limits updated accordingly
   - Some previously "excessive" documents should become viable

3. **Test Performance với Existing Features**:
   - Use dual chat modes với long conversation (memory system active)
   - Verify performance remains acceptable với both systems working
   - Memory retrieval + Full Context should still respond within 10 seconds

4. **Security Integration Test**:
   - Verify chat mode selection doesn't bypass API key security
   - Both RAG và Full Context should use secure keychain-stored keys
   - Test biometric authentication still required for API access

#### **Expected Results:**
- ✅ Chat modes integrate seamlessly với conversation memory
- ✅ Model switching updates context limits correctly
- ✅ Combined features maintain acceptable performance
- ✅ Security boundaries preserved across all modes
- ✅ No conflicts between dual chat modes và existing features

---

## 📊 **Sprint 4.6 Test Execution Guidelines**

### **Pre-Test Setup:**
1. **Device Requirements**:
   - iPhone/iPad với iOS 17+
   - Minimum 2GB free storage
   - Stable internet connection
   - Face ID/Touch ID enabled

2. **Test Data Preparation**:
   - Small document (5-15k chars): Simple report or article
   - Medium document (20-50k chars): Technical manual or specification
   - Large document (100k+ chars): Complete guidebook or research paper
   - Mixed format documents: PDF, images với text, plain text files

3. **Environment Setup**:
   - Fresh app install recommended for baseline testing
   - Valid API keys configured for multiple providers (GPT-4, Claude)
   - Clear app storage để ensure clean starting state

### **Success Criteria - Sprint 4.6:**
- **Context Intelligence**: Accurate size calculation và mode recommendations
- **Mode Selection**: Clear, responsive dual mode interface
- **Full Context Processing**: Complete document content inclusion working
- **Performance**: Context analysis <100ms, Full Context responses <10s
- **Integration**: Seamless interaction với existing Document Intelligence features
- **User Experience**: Intuitive mode selection và clear visual feedback

### **Critical Path Testing:**
1. **AT-4.6.1** → **AT-4.6.2** → **AT-4.6.4**: Core functionality flow
2. **AT-4.6.3** → **AT-4.6.5**: Enhanced UI experience
3. **AT-4.6.6** → **AT-4.6.7**: Advanced scenarios và integration

### **Performance Benchmarks:**
- Context size calculation: <100ms per document
- Mode switching: <200ms UI response time
- Full Context mode: Response starts within 5 seconds
- Multi-document analysis: <500ms for 5 documents
- Memory footprint: <50MB additional for Full Context features

---

**These acceptance tests validate Sprint 4.6's Dual Chat Mode implementation delivers intelligent, user-friendly document interaction capabilities on real iOS devices. Each test ensures the system provides appropriate mode recommendations, smooth mode switching, và optimal performance across different document sizes và usage scenarios.** 🎯