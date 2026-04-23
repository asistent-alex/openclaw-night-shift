---
topic: Add integration tests for nexlink Exchange sync operations
repo: nexlink
agent: dev-nexlink
type: test
priority: high
---

## Context

The `sync` module in nexlink handles Exchange → Nextcloud synchronization (emails, contacts, tasks). It currently lacks automated tests, which makes refactoring risky.

## Goal

Write comprehensive integration tests for the sync module.

## Scope

Test these sync operations:
1. **Email sync** — sync emails from Exchange to Nextcloud Mail
2. **Contact sync** — sync contacts bidirectionally
3. **Task sync** — sync tasks from Exchange to Nextcloud Tasks
4. **Conflict resolution** — when item exists in both systems
5. **Error handling** — network failures, auth errors, etc.

## Implementation

1. Create `tests/integration/test_sync.py`
2. Use `pytest` framework
3. Mock EWS and Nextcloud APIs (don't hit real servers)
4. Test fixtures for sample data
5. Run with: `python -m pytest tests/integration/test_sync.py -v`

## Test Structure

```python
class TestEmailSync:
    def test_sync_new_email(self): ...
    def test_sync_duplicate_email(self): ...
    def test_sync_deleted_email(self): ...

class TestContactSync:
    def test_sync_new_contact(self): ...
    def test_sync_updated_contact(self): ...
    def test_conflict_resolution(self): ...

class TestErrorHandling:
    def test_ews_auth_error(self): ...
    def test_nextcloud_timeout(self): ...
```

## Constraints

- **DO NOT MERGE PR automatically** — open PR and wait for human review
- Mock EWS/Nextcloud APIs (don't hit real servers)
- Keep test data isolated (fixtures)
- Tests must pass before PR is opened

## Workflow

1. Create branch: `sync-tests`
2. Write tests incrementally (email → contact → task → error)
3. Run `pytest` after each test group
4. Open PR when all tests pass
5. Report PR URL and STOP — wait for human review
6. Do NOT merge — human will review and merge

## Acceptance Criteria

- [ ] >80% code coverage for sync module
- [ ] All tests pass: `pytest tests/integration/test_sync.py`
- [ ] Mocking doesn't leak to production code
- [ ] CI integration (GitHub Actions runs tests)
- [ ] README updated with test instructions

---
Built by Firma de AI, supported by Firma de IT
https://firmade.ai | https://firmade.it
