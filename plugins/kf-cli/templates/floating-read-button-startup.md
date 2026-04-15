<%*
// Floating Read Status Button - Startup Template
// Creates an icon-only button inside the note area that reflects read status

// Clean up any existing buttons from previous sessions
const existingContainer = document.getElementById('floating-read-btn-container');
if (existingContainer) {
    existingContainer.remove();
}

// Clean up any existing event handlers
if (window.floatingReadBtnUnregister) {
    window.floatingReadBtnUnregister();
}

// Create the button
const statusBtn = document.createElement('button');
statusBtn.id = 'floating-read-btn-container';
statusBtn.style.cssText = `
    position: absolute;
    bottom: 12px;
    right: 12px;
    z-index: 100;
    width: 36px;
    height: 36px;
    padding: 0;
    border: none;
    border-radius: 50%;
    font-size: 18px;
    cursor: pointer;
    background: transparent;
    box-shadow: none;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
`;

// Function to find and attach button to the note area
function attachButtonToNoteArea() {
    // Remove from current parent if exists
    if (statusBtn.parentElement) {
        statusBtn.remove();
    }

    // Find the active markdown view's content area
    const activeLeaf = app.workspace.activeLeaf;
    if (!activeLeaf) return false;

    const viewContent = activeLeaf.view?.containerEl?.querySelector('.markdown-reading-view, .markdown-source-view');
    if (!viewContent) return false;

    // Make sure the parent has relative positioning
    const parent = viewContent.closest('.view-content');
    if (parent) {
        parent.style.position = 'relative';
        parent.appendChild(statusBtn);
        return true;
    }
    return false;
}

// Function to update button based on current file's read status
function updateReadButton() {
    const file = app.workspace.getActiveFile();

    if (!file || file.extension !== 'md') {
        statusBtn.style.display = 'none';
        return;
    }

    // Attach button to current note area
    if (!attachButtonToNoteArea()) {
        statusBtn.style.display = 'none';
        return;
    }

    const fileCache = app.metadataCache.getFileCache(file);
    const frontmatter = fileCache?.frontmatter;

    statusBtn.style.display = 'flex';

    // Check if this note has read tracking
    if (frontmatter && typeof frontmatter.read !== 'undefined') {
        if (frontmatter.read === true) {
            // Already read - show open book icon
            statusBtn.textContent = '📖';
            statusBtn.style.background = 'transparent';
            statusBtn.title = 'Mark as Unread';
            statusBtn.dataset.action = 'toggle';
        } else {
            // Not read yet - show closed book icon
            statusBtn.textContent = '📕';
            statusBtn.style.background = 'transparent';
            statusBtn.title = 'Mark as Read';
            statusBtn.dataset.action = 'toggle';
        }
    } else {
        // No read field - offer to add tracking
        statusBtn.textContent = '📚';
        statusBtn.style.background = 'transparent';
        statusBtn.title = 'Add Read Tracking';
        statusBtn.dataset.action = 'add';
    }
}

// Handle button click based on action
statusBtn.addEventListener('click', async (e) => {
    e.stopPropagation();
    const file = app.workspace.getActiveFile();
    if (!file) return;

    const action = statusBtn.dataset.action;

    if (action === 'add') {
        await app.fileManager.processFrontMatter(file, (fm) => {
            fm.read = false;
        });
        new Notice('Read tracking added!');
    } else {
        const fileCache = app.metadataCache.getFileCache(file);
        const frontmatter = fileCache?.frontmatter;
        const currentStatus = frontmatter?.read ?? false;
        const newStatus = !currentStatus;

        await app.fileManager.processFrontMatter(file, (fm) => {
            fm.read = newStatus;
        });
        new Notice(newStatus ? 'Marked as Read' : 'Marked as Unread');
    }

    setTimeout(updateReadButton, 100);
});

// Hover effect
statusBtn.addEventListener('mouseenter', () => {
    statusBtn.style.transform = 'scale(1.2)';
    statusBtn.style.opacity = '0.8';
});
statusBtn.addEventListener('mouseleave', () => {
    statusBtn.style.transform = 'scale(1)';
    statusBtn.style.opacity = '1';
});

// Listen for file/view changes
const leafChangeRef = app.workspace.on('active-leaf-change', () => {
    setTimeout(updateReadButton, 50);
});

const layoutChangeRef = app.workspace.on('layout-change', () => {
    setTimeout(updateReadButton, 50);
});

// Listen for metadata changes
const metadataChangeRef = app.metadataCache.on('changed', (file) => {
    const activeFile = app.workspace.getActiveFile();
    if (activeFile && file.path === activeFile.path) {
        setTimeout(updateReadButton, 50);
    }
});

// Store cleanup function
window.floatingReadBtnUnregister = () => {
    app.workspace.offref(leafChangeRef);
    app.workspace.offref(layoutChangeRef);
    app.metadataCache.offref(metadataChangeRef);
};

// Initial update
setTimeout(updateReadButton, 100);
-%>
