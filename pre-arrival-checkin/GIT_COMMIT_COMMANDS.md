# Git Commit Commands

## If Git Repository is NOT Initialized:

```bash
# Navigate to your pre-arrival-checkin project directory
cd pre-arrival-checkin

# Initialize git repository (if not already done)
git init

# Add remote repository (replace with your actual repository URL)
git remote add origin https://github.com/yourusername/pre-arrival-checkin.git
```

## Git Commands to Commit and Push:

```bash
# Navigate to your pre-arrival-checkin project directory
cd pre-arrival-checkin

# Check status of files
git status

# Add all new and modified files
git add .

# Or add specific files:
git add src/main/java/com/petrabooking/checkin/controller/CheckInController.java
git add src/main/resources/templates/further-details.html
git add src/main/resources/templates/accessibility-form.html

# Commit with a descriptive message
git commit -m "Add Further Details and Accessibility Form features

- Add further-details.html page with Purpose of Stay, Eating Habits, Allergies, and Accessibility Needs sections
- Add accessibility-form.html with expandable accordion sections for detailed accessibility requirements
- Add showFurtherDetails() method to display further details page
- Add submitFurtherDetails() method to save further details data
- Add showAccessibilityForm() method to display accessibility form in popup
- Add submitAccessibilityForm() method to save accessibility form data
- Update submitCheckIn() to redirect to further-details page instead of confirmation
- Implement session-based data persistence for all form data
- Add character counters and form validation
- Add progress bar and navigation between steps"

# Push to remote repository
git push origin main

# Or if your branch is named 'master':
git push origin master
```

## Alternative Shorter Commit Message:

```bash
git commit -m "feat: Add Further Details and Accessibility Form pages with session persistence"
```

## If You Need to Set Up Git User (First Time):

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Files Changed:

1. `src/main/java/com/petrabooking/checkin/controller/CheckInController.java` - Updated with 4 new methods
2. `src/main/resources/templates/further-details.html` - New file
3. `src/main/resources/templates/accessibility-form.html` - New file

## Quick One-Liner Commands:

```bash
# Add, commit, and push in one go (if you're confident)
cd pre-arrival-checkin
git add .
git commit -m "feat: Add Further Details and Accessibility Form features"
git push origin main
```
