# REFACTORING_SPEC.md | v0.5.0 Post-Quality Improvements

## SPECIFICATION

### Context
- **Codebase State**: 100/100 quality score (0 credo issues, 0 dialyzer warnings)
- **Analysis Scope**: ~2042 modules/functions across the Ashfolio codebase
- **Current Quality**: Excellent - no dead code or obvious issues detected by static analysis
- **Objective**: Identify legitimate consolidation opportunities for improved maintainability

### Goals
1. **Evidence-Based Assessment**: Only pursue changes backed by concrete evidence
2. **Risk-Aware Design**: Evaluate pros/cons/risks for each proposed change
3. **Dependency Mapping**: Understand impact chains before making changes
4. **Maintainability Focus**: Improve code organization without breaking functionality

### Success Criteria
- Reduced code duplication (measurable)
- Improved API consistency (testable)
- Maintained or improved test coverage
- Zero functional regressions
- Clear dependency relationships

---

## DESIGN ANALYSIS

### Phase 1: Evidence Gathering

#### 1.1 Formatting Logic Investigation
**Hypothesis**: Multiple formatting implementations exist
**Evidence Required**:
- [ ] Inventory all currency/percentage/number formatting functions
- [ ] Compare implementations for true duplication vs specialized behavior
- [ ] Map current usage patterns and call sites
- [ ] Assess breaking change risk for consolidation

**Risk Assessment Framework**:
- **LOW**: Functions with identical logic and no specialized behavior
- **MEDIUM**: Similar logic but different edge case handling
- **HIGH**: Different implementations serving different contexts

#### 1.2 Mathematical Operations Assessment  
**Hypothesis**: Duplicate math functions across calculators
**Evidence Required**:
- [ ] Catalog all mathematical functions (power, root, compound interest, etc.)
- [ ] Compare precision requirements and edge case handling
- [ ] Identify which are truly duplicated vs contextually specialized
- [ ] Map dependencies and test coverage

#### 1.3 Data Transformation Patterns
**Hypothesis**: Repeated list processing patterns in LiveViews
**Evidence Required**:
- [ ] Document common data transformation patterns
- [ ] Assess whether patterns are incidental similarity vs true duplication
- [ ] Evaluate extraction value vs abstraction overhead
- [ ] Consider domain-specific vs generic utility trade-offs

### Phase 2: Design Evaluation

#### 2.1 Consolidation Design Patterns
For each identified opportunity:

**API Design Questions**:
- Does consolidation improve or complicate the calling interface?
- Are we creating proper abstractions or just moving code?
- Will the new API be more intuitive than current patterns?
- What's the cognitive load of the new vs old approach?

**Dependency Impact Analysis**:
- What modules currently depend on existing implementations?
- How many call sites need to be updated?
- Are there circular dependency risks with proposed modules?
- What's the migration path and rollback strategy?

#### 2.2 Risk Assessment Matrix

| Risk Level | Criteria | Approach |
|------------|----------|----------|
| **LOW** | Identical implementations, isolated modules, comprehensive tests | Proceed with consolidation |
| **MEDIUM** | Similar but not identical, moderate usage, partial test coverage | Design with feature parity first |
| **HIGH** | Different behaviors, widely used, incomplete test coverage | Document trade-offs, consider alternatives |

### Phase 3: Task Planning

#### 3.1 Evidence-First Methodology
1. **Research Phase**: Gather concrete evidence before design
2. **Impact Analysis**: Map all dependencies and breaking changes  
3. **Design Phase**: Create detailed API designs with pros/cons
4. **Validation Phase**: Test designs with real usage patterns
5. **Implementation Phase**: Execute with rollback capability

#### 3.2 Decision Framework
For each proposed change:

**PROCEED IF**:
- Clear evidence of true duplication (not just similarity)
- Consolidation genuinely improves maintainability
- Breaking changes are minimal and well-understood
- Test coverage supports safe refactoring
- API design is demonstrably better than current state

**DEFER IF**:
- Evidence is ambiguous or insufficient
- Risk/benefit analysis is unclear
- Dependencies are complex or poorly understood
- Current code works well and is well-tested

---

## TASKS

### Task 1: Comprehensive Evidence Collection
**Objective**: Replace assumptions with concrete analysis

**Subtasks**:
- [ ] Audit all formatting functions with line-by-line comparison
- [ ] Map mathematical function usage and identify true duplicates
- [ ] Document data transformation patterns with usage frequency
- [ ] Create dependency graphs for proposed consolidation targets

**Deliverable**: Evidence report with specific file:line references and duplication metrics

**Risk**: None - purely investigative

### Task 2: API Design and Impact Analysis
**Objective**: Design proposed APIs with full impact assessment

**Subtasks**:
- [ ] Design consolidated APIs with backward compatibility analysis
- [ ] Map breaking changes and migration requirements
- [ ] Assess test coverage gaps for refactoring targets
- [ ] Calculate effort vs benefit for each opportunity

**Deliverable**: Detailed design documents with risk/benefit analysis

**Risk**: Low - design only, no implementation

### Task 3: Validation and Decision
**Objective**: Validate designs against real usage patterns

**Subtasks**:
- [ ] Prototype key API changes in isolated modules
- [ ] Test proposed APIs against current usage patterns
- [ ] Gather feedback on API ergonomics and complexity
- [ ] Make go/no-go decisions based on evidence

**Deliverable**: Final implementation plan with evidence-based prioritization

**Risk**: Low - validation can be rolled back

---

## SUCCESS METRICS

### Quantitative Measures
- **Code Reduction**: Measurable LOC reduction from true consolidation
- **API Consistency**: Number of different patterns for same operations
- **Test Coverage**: Maintained or improved coverage percentages
- **Build Performance**: No degradation in compilation time

### Qualitative Measures  
- **Developer Experience**: Is the consolidated API easier to use?
- **Maintainability**: Are changes easier to make across the codebase?
- **Discoverability**: Is it easier to find the right function to use?
- **Documentation**: Is the consolidated API easier to document and understand?

---

## NEXT STEPS

1. **Execute Task 1**: Evidence collection with concrete analysis
2. **Review Findings**: Assess whether significant opportunities actually exist
3. **Proceed Conditionally**: Only move to design if evidence supports benefits
4. **Document Decisions**: Record why we proceed or defer on each opportunity

This spec prioritizes evidence over assumptions and ensures we only invest effort in changes that demonstrably improve the codebase.