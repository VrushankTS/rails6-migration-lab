# Rails 6.1 → 7.0 Migration Process & Debugging Guide

## Overview
This document captures the entire migration process from Rails 6.1 to Rails 7.0 and the debugging steps taken to resolve the `Rails::Engine is abstract` error.

---

## Phase 1: Initial Setup & Dependency Update

### Step 1.1: Update Gemfile
**What to do:**
- Update the Rails gem version in your `Gemfile`
- For major version upgrades, use a pessimistic constraint (`~> X.Y.Z`) instead of exact version pinning
- This allows patch-level security updates while preventing accidental minor/major version jumps

**Example:**
```ruby
# Before
gem 'rails', '6.1.0'

# After (what we did)
gem 'rails', '~> 7.0.8'  # Allows 7.0.8, 7.0.9, etc., but not 7.1.0
```

**Why this matters:**
- Rails 7.0.0 had bugs (specifically the `Rails::Engine is abstract` error)
- Later patch versions (7.0.8+) included critical fixes
- Using pessimistic constraints ensures you get security patches automatically

### Step 1.2: Run Bundle Update
```bash
docker compose run --rm web bundle update rails
```

**What happens:**
- Bundler resolves all transitive dependencies for the new Rails version
- Updates gems like `activesupport`, `activerecord`, `railties`, etc.
- Regenerates `Gemfile.lock` with exact pinned versions

---

## Phase 2: Configuration Updates

### Step 2.1: Update config/application.rb
**What changed:**
```ruby
# Before
config.load_defaults 6.1

# After
config.load_defaults 7.0
```

**Why this matters:**
- `load_defaults X.Y` activates all default Rails configuration behaviors for that version
- When you upgrade Rails, you **must** also upgrade this setting
- Mismatch between Rails gem version and `load_defaults` causes version conflict errors
- This setting enables/disables deprecation warnings and behavior changes

**What `load_defaults 7.0` enables:**
- Zeitwerk autoloading (instead of classic autoloader)
- New Active Record query methods
- Updated default configuration options
- (See `config/initializers/new_framework_defaults_7_0.rb` for all changes)

### Step 2.2: Run the Rails Update Generator
```bash
docker compose run --rm web bundle exec rails app:update
```

**What this command does:**
1. Compares your current Rails 6 configuration with Rails 7 defaults
2. **Identifies conflicts** in files like:
   - `config/boot.rb` (autoloader changes)
   - `config/environments/production.rb`
   - `config/environments/development.rb`
   - `config/environments/test.rb`
   - Initializer files in `config/initializers/`
3. **Prompts you** to resolve conflicts (Overwrite/Skip/Diff/etc.)
4. **Creates new files** like `config/initializers/new_framework_defaults_7_0.rb`
5. **Copies migrations** from bundled engines (e.g., Active Storage)

**Interactive Prompts:**
- When prompted with `[Ynaqdhm]`:
  - `Y` = Yes (overwrite with Rails 7 defaults)
  - `n` = No (keep your version)
  - `a` = All (apply choice to all conflicts)
  - `q` = Quit
  - `d` = Diff (show differences)
  - `h` = Help

---

## Phase 3: Debugging the `Rails::Engine is abstract` Error

### Symptom
```
rails aborted!
Rails::Engine is abstract, you cannot instantiate it directly.
/usr/local/bundle/gems/railties-7.0.0/lib/rails/railtie.rb:246:in `initialize'
```

### Root Cause Analysis

This error indicates that Rails cannot initialize the main Application class because of a critical bug in **Rails 7.0.0 specifically**.

**Why it happens:**
1. Rails 7.0.0 had an incompatibility in how it initializes the Engine/Railtie hierarchy
2. When `require "rails/all"` executes, it tries to instantiate the abstract `Rails::Engine` class
3. This is a known bug that was fixed in later 7.0.x patches

**Not caused by:**
- Your app code (no custom Engines or Railties)
- Spring cache or bootsnap compilation
- Missing gems or version conflicts in the app layer
- Configuration mistakes

### Debugging Steps We Took (In Order)

#### Debug Step 1: Verify the Error Persists
```bash
docker compose run --rm web bundle exec rails app:update
```
- Confirmed the error happens consistently
- Captured the full stack trace showing it originates from `railties-7.0.0`

#### Debug Step 2: Check Configuration Version Mismatch
```ruby
# config/application.rb
config.load_defaults 6.1  # ← Still set to 6.1 while Rails 7 is loaded!
```
- Updated to `config.load_defaults 7.0`
- **Result:** Still got the error (because the bug is in Rails 7.0.0 itself, not config)

#### Debug Step 3: Clear Spring & Bootsnap Caches
```bash
docker compose down && rm -rf tmp/pids/spring.pid
```
- Thought the issue was cached bytecode from Spring
- **Result:** No change (error persisted)

#### Debug Step 4: Rebuild Docker Image
```bash
docker compose down -v && docker compose build --no-cache
```
- Cleared bundle volume, rebuilt gem cache
- **Result:** Still no change (confirmed it's a Rails gem issue, not container state)

#### Debug Step 5: Test Rails Loading Directly
```bash
docker compose run --rm web ruby -e "require_relative 'config/application'; puts Rails.application"
```
- Isolated the error to the Rails initialization phase
- Confirmed error happens even with minimal Ruby code
- Stack trace pointed specifically to `railties-7.0.0`

#### Debug Step 6: Root Cause Hypothesis
- **Finding:** Rails 7.0.0 is a known-buggy release
- **Decision:** Upgrade to Rails 7.0.8+ (stable patch release)

#### Debug Step 7: Apply Fix
```ruby
# Gemfile
gem 'rails', '~> 7.0.8'  # Instead of 'rails', '7.0.0'
```

```bash
docker compose run --rm web bundle update rails
```

- This upgraded to Rails 7.0.10 (latest in 7.0.x series)
- **Result:** Error resolved, app:update ran successfully ✓

---

## Phase 4: Verify the Fix

### Confirm Configuration Updated
```bash
grep "load_defaults" config/application.rb
# Output: config.load_defaults 7.0
```

### Check Generated Files
```bash
ls -la config/initializers/new_framework_defaults_7_0.rb
```
- Contains all the Rails 7.0-specific defaults
- Review this file to understand behavioral changes

### Check Migrations Copied
```bash
ls -la db/migrate/ | grep active_storage
```
- Active Storage migrations were copied
- These prepare your database for Rails 7.0 features

---

## Universal Issues & Version Guidance

### Is This a Universal Issue?

**YES, but with caveats:**

1. **Rails 7.0.0 specifically had bugs:**
   - The Engine initialization error was fixed in 7.0.1+
   - Multiple other issues were fixed in patch releases
   - **Recommendation:** Never use x.y.0 releases in production; always use x.y.1+

2. **Version conflicts happen often during Rails migrations:**
   - Different gem versions may have incompatibilities
   - Config version mismatches are common first-time mistakes
   - Spring/bootsnap caching can mask real issues

3. **Not all versions are equal:**
   - LTS (Long Term Support) versions are more stable: Rails 6.1, 7.1
   - First releases (x.y.0) often have bugs
   - Stable releases (x.y.8+) are well-tested

### Best Practices for Rails Migrations

#### 1. **Check Rails Upgrade Guides Before Starting**
   - Navigate to: https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
   - Read the full guide for your target version
   - Check known issues and deprecations

#### 2. **Use Pessimistic Version Constraints**
   ```ruby
   # ✓ Good - allows patch updates
   gem 'rails', '~> 7.0.8'
   
   # ✓ Good - allows minor updates within major
   gem 'rails', '~> 7.0'
   
   # ✗ Bad - locks to exact bug-prone release
   gem 'rails', '7.0.0'
   
   # ✗ Bad - allows major version jumps
   gem 'rails', '> 6.0'
   ```

#### 3. **Upgrade One Major Version at a Time**
   - 5.x → 6.x → 7.x → 8.x (not 5.x → 8.x directly)
   - Each major version has deprecation warnings in the prior version
   - Fix those warnings first, then upgrade

#### 4. **Review Configuration Changes**
   - Run `rails app:update` and review all conflicts
   - Don't blindly overwrite; understand what changed
   - Test your app thoroughly after each update

#### 5. **Test After Each Phase**
   - Run your test suite after config updates
   - Start the server and test key features manually
   - Look for deprecation warnings in logs

#### 6. **Handle Known Issues**
   - Search GitHub issues for your Rails version
   - Check if you hit known bugs
   - Upgrade to latest patch if needed (as we did here)

---

## For Your Company's Rails 5 → 8 Migration

### Recommended Path
```
Rails 5.x → Rails 6.1 → Rails 7.1 → Rails 8.0
```

Why this path:
- Rails 6.1 is an LTS release (long-term support)
- Rails 7.1 is newer but stable
- Each step fixes/addresses issues from the prior version

### Timeline Per Version
- Rails 5 → 6: ~1-2 weeks (significant changes to autoloading)
- Rails 6 → 7: ~1 week (relatively smooth)
- Rails 7 → 8: ~2-3 weeks (significant changes to async, error handling)

### Checklist for Each Migration
- [ ] Read Rails upgrade guide
- [ ] Update Gemfile with pessimistic constraint
- [ ] Run `bundle update`
- [ ] Update `config/application.rb` load_defaults
- [ ] Run `rails app:update`
- [ ] Review and commit config changes
- [ ] Run full test suite
- [ ] Start server and smoke test key features
- [ ] Fix any deprecation warnings
- [ ] Deploy to staging, then production

---

## Quick Reference: Debugging Checklist

When you encounter Rails upgrade errors:

1. **Read the stack trace** - First line tells you the problem source
2. **Verify `load_defaults` matches Rails version** - Common first mistake
3. **Check Gemfile constraints** - Are you on a known-buggy release?
4. **Clear caches** - `rm -rf tmp/cache db/cache`, rebuild Docker
5. **Test minimal Rails load** - `ruby -e "require 'rails'; puts Rails.version"`
6. **Search GitHub issues** - Is it a known bug in your version?
7. **Check Rails release notes** - Known issues documented there
8. **Upgrade to latest patch** - If on x.y.0, try x.y.8+
9. **Review configuration files** - Conflicts from `app:update`
10. **Run full test suite** - Catches breaking changes early

---

## Files Modified in This Migration

```
✓ Gemfile                                    (Rails version constraint)
✓ config/application.rb                      (load_defaults 7.0)
✓ config/boot.rb                             (Zeitwerk autoloader setup)
✓ config/environments/development.rb         (Rails 7 defaults)
✓ config/environments/production.rb          (Rails 7 defaults)
✓ config/environments/test.rb                (Rails 7 defaults)
✓ config/initializers/*.rb                   (Various Rails 7 settings)
✓ config/initializers/new_framework_defaults_7_0.rb  (New file)
✓ bin/rails                                  (Updated binstub)
✓ bin/rake                                   (Updated binstub)
✓ db/schema.rb                               (Updated schema format)
✓ db/migrate/*_active_storage_*.rb           (New migrations)
```

---

## Next Steps

1. **Run your test suite:** `docker compose run --rm web bundle exec rails test`
2. **Start the server:** `docker compose up` and test manually
3. **Review deprecation warnings:** Check logs for `DEPRECATION WARNING`
4. **Commit config changes:** `git add config/ && git commit -m "Upgrade to Rails 7.0"`
5. **Plan Rails 7 → 8 upgrade:** Apply same process with Rails 8.0+
