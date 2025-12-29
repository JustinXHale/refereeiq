# Changelog

## [0.9.5+5]
- Improved sofia questioning
- added laws injest.js to pull from World Rugby
- added law.js to chunk laws
- added chat.js to detect online clarifications
- added gldo_permutations.json and supplemental .js files 

## [0.9.4+4]
- update SHA for google signin

## [0.9.4+3]
### Changed
- Filtering in the leaderboard. Added labels and changed default filtering to Daily.
- Removed easy, medium, hard questions and just made it standard with 5 points for each question.
- added sha for google auth signin
- moved all prompts to single js function
- delete account link in profile settings
- update leaderboard player profile (still not complete, its not accessing photos)

## [0.9.3+1] - 2025-08-10
### Changed
- Updated Android app display name to "RefereeIQ" (capitalized) in `AndroidManifest.xml`.
- Adjusted trophy icon size and spacing in Daily Challenge completion view.
- Fine-tuned spacing between "You scored" and "Next drop" text.
- Maintained challenge lock state without greying out completed challenges.

### Fixed
- Ensured completed challenges correctly show inline congratulations with score/rank.
- Addressed case where Challenge History items could have missing law references.
- Confirmed Daily Challenge limit logic is working as intended after refresh.
- Removed false empty state when a completed challenge exists.

### Maintenance
- Flutter clean/build to resolve stale cache and state issues.


## [0.9.1+0] - 2025-08-09
### Added
- Custom empty states for:
    - Daily Challenge (with upcoming game update messaging)
    - Leaderboard
    - Favorites (with how-to-add instructions)
- `GetRankForCurrentBlock` function for more accurate rank tracking

### Changed
- Updated Favorites empty state layout for better vertical alignment
- Changed empty state star icon to app's yellow color
- Updated Leaderboard heading row color code to use `WidgetStateColor` (MaterialStateColor deprecated)
- Restored correct/incorrect answer highlight colors in challenges

### Removed
- "Pro Tip" snippet from Daily Challenge empty state
- Obsolete UI elements and unused code

---
