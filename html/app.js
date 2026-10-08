const messages = document.getElementById('messages');
const suggestions = document.getElementById('suggestions');
const inputBox = document.getElementById('inputBox');
const input = document.getElementById('chatInput');

let isAdmin = false;
let commands = [];
let visible = [];
let selected = 0;
let chatIsOpen = false;
let messageFadeTimer = null;
let messageHideTimer = null;
const maxStoredMessages = 50;

// Lähetettyjen /komentojen historia.
// Nuoli ylös = vanhempi komento
// Nuoli alas = uudempi komento
const commandHistory = [];
const maxCommandHistory = 50;
let historyIndex = -1;
let browsingHistory = false;

function stripFiveMFormatting(value) {
    return String(value ?? '')
        .replace(/\^[0-9]/g, '')
        .replace(/\^[*_~=+\-]/g, '');
}

window.addEventListener('message', (event) => {
    const p = event.data;

    if (!p || !p.action) return;

    if (p.action === 'open') {
        chatIsOpen = true;
        cancelMessageTimers();
        showStoredMessages();
        inputBox.classList.add('open');
        input.value = '';
        resetHistoryNavigation();
        hideSuggestions();

        setTimeout(() => input.focus(), 0);
        return;
    }

    if (p.action === 'close') {
        chatIsOpen = false;
        inputBox.classList.remove('open');
        input.value = '';
        resetHistoryNavigation();
        hideSuggestions();

        // Piilota nopeasti, mutta ÄLÄ tyhjennä historiaa.
        hideStoredMessagesFast();
        return;
    }

    if (p.action === 'adminState') {
        isAdmin = p.isAdmin === true;
        commands = isAdmin && Array.isArray(p.commands) ? p.commands : [];

        if (!isAdmin) hideSuggestions();
        return;
    }

    if (p.action === 'message') {
        addMessage(p.data);
        return;
    }

    if (p.action === 'clear') {
        messages.innerHTML = '';
    }
});

function addMessage(data) {
    if (!data) return;

    const nameText = stripFiveMFormatting(data.name || 'Järjestelmä');
    const messageText = stripFiveMFormatting(data.message || '');
    const kind = ['twitter', 'report', 'admin', 'system', 'normal'].includes(data.kind)
        ? data.kind
        : 'system';

    const item = document.createElement('article');
    item.className = `message ${kind}`;

    const header = document.createElement('div');
    header.className = 'header';

    const icon = document.createElement('span');
    icon.className = 'icon';

    if (kind === 'twitter') {
        icon.textContent = '🐦';
    } else if (kind === 'report') {
        icon.textContent = '🚨';
    } else if (kind === 'admin') {
        icon.textContent = '🛡️';
    } else if (kind === 'normal') {
        icon.textContent = '💬';
    } else {
        icon.textContent = '⚙️';
    }

    const name = document.createElement('span');
    name.className = 'name';
    name.textContent = nameText;

    const text = document.createElement('div');
    text.className = 'text';
    text.textContent = messageText;

    const time = document.createElement('span');
    time.className = 'time';
    time.textContent = data.time || currentTime();

    header.append(icon, name);
    item.append(header, text, time);
    messages.appendChild(item);

    // Säilytä chat-historia muistissa myös silloin kun chat on piilossa.
    while (messages.children.length > maxStoredMessages) {
        messages.removeChild(messages.firstChild);
    }

    messages.scrollTop = messages.scrollHeight;

    if (chatIsOpen) {
        showStoredMessages();
    } else {
        // Kun uusi viesti tulee chatin ollessa kiinni, näytä viestit hetken
        // ja häivytä ne rauhallisesti pois. Historia jää silti talteen.
        showIncomingMessagesTemporarily();
    }
}

function cancelMessageTimers() {
    if (messageFadeTimer) {
        clearTimeout(messageFadeTimer);
        messageFadeTimer = null;
    }

    if (messageHideTimer) {
        clearTimeout(messageHideTimer);
        messageHideTimer = null;
    }
}

function showStoredMessages() {
    cancelMessageTimers();
    messages.classList.remove('messages-hidden', 'messages-fading');
    messages.classList.add('messages-visible');
    messages.scrollTop = messages.scrollHeight;
}

function hideStoredMessagesFast() {
    cancelMessageTimers();
    messages.classList.remove('messages-visible', 'messages-fading');
    messages.classList.add('messages-hidden');
}

function showIncomingMessagesTemporarily() {
    cancelMessageTimers();
    messages.classList.remove('messages-hidden', 'messages-fading');
    messages.classList.add('messages-visible');

    // Uusi viesti näkyy ensin normaalisti 5 sekuntia.
    messageFadeTimer = setTimeout(() => {
        if (chatIsOpen) return;

        messages.classList.remove('messages-visible');
        messages.classList.add('messages-fading');

        // Hidas 2 sekunnin häivytys. Vain näkyvyys muuttuu, ei historia.
        messageHideTimer = setTimeout(() => {
            if (chatIsOpen) return;
            messages.classList.remove('messages-fading');
            messages.classList.add('messages-hidden');
        }, 2000);
    }, 5000);
}

function currentTime() {
    return new Date().toLocaleTimeString('fi-FI', {
        hour: '2-digit',
        minute: '2-digit'
    });
}

input.addEventListener('input', () => {
    // Jos pelaaja kirjoittaa itse, lopetetaan historian selaus.
    if (browsingHistory) {
        browsingHistory = false;
        historyIndex = -1;
    }

    updateSuggestions();
});

input.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
        closeChat();
        return;
    }

    // Kun input on tyhjä tai historiaa on jo alettu selaamaan,
    // nuolinäppäimet selaavat aiemmin lähetettyjä /komentoja.
    if (event.key === 'ArrowUp') {
        if (browsingHistory || input.value.trim() === '') {
            event.preventDefault();
            historyUp();
            return;
        }

        // Muulloin nuoli ylös voi edelleen liikkua autocomplete-listassa.
        if (visible.length > 0) {
            event.preventDefault();
            selected = (selected - 1 + visible.length) % visible.length;
            updateSelection();
            return;
        }
    }

    if (event.key === 'ArrowDown') {
        if (browsingHistory) {
            event.preventDefault();
            historyDown();
            return;
        }

        // Muulloin nuoli alas voi edelleen liikkua autocomplete-listassa.
        if (visible.length > 0) {
            event.preventDefault();
            selected = (selected + 1) % visible.length;
            updateSelection();
            return;
        }
    }

    if (event.key === 'Tab' && visible.length > 0) {
        event.preventDefault();
        chooseSelected();
        return;
    }

    if (event.key === 'Enter') {
        event.preventDefault();
        sendMessage();
    }
});

function addToCommandHistory(message) {
    if (!message.startsWith('/')) return;

    // Ei lisätä samaa komentoa kahdesti peräkkäin.
    if (commandHistory[commandHistory.length - 1] !== message) {
        commandHistory.push(message);
    }

    while (commandHistory.length > maxCommandHistory) {
        commandHistory.shift();
    }

    resetHistoryNavigation();
}

function historyUp() {
    if (commandHistory.length === 0) return;

    if (!browsingHistory) {
        browsingHistory = true;
        historyIndex = commandHistory.length - 1;
    } else if (historyIndex > 0) {
        historyIndex--;
    }

    input.value = commandHistory[historyIndex] || '';
    hideSuggestions();
    moveCursorToEnd();
}

function historyDown() {
    if (!browsingHistory || commandHistory.length === 0) return;

    if (historyIndex < commandHistory.length - 1) {
        historyIndex++;
        input.value = commandHistory[historyIndex] || '';
    } else {
        resetHistoryNavigation();
        input.value = '';
    }

    hideSuggestions();
    moveCursorToEnd();
}

function resetHistoryNavigation() {
    historyIndex = -1;
    browsingHistory = false;
}

function moveCursorToEnd() {
    const end = input.value.length;
    input.focus();
    input.setSelectionRange(end, end);
}

function updateSuggestions() {
    const value = input.value;

    if (!isAdmin || !value.startsWith('/') || value.includes(' ')) {
        hideSuggestions();
        return;
    }

    const query = value.slice(1).toLowerCase();
    selected = 0;

    showSuggestions(
        commands.filter((command) =>
            command.command.toLowerCase().startsWith(query)
        )
    );
}

function sendMessage() {
    const message = input.value.trim();

    // Jos kenttä on tyhjä ja painetaan Enteriä, sulje chat.
    if (!message) {
        closeChat();
        return;
    }

    addToCommandHistory(message);

    fetch(`https://${GetParentResourceName()}/sendMessage`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ message })
    });

    input.value = '';
    hideSuggestions();
}

function closeChat() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function showSuggestions(list) {
    if (!isAdmin || !Array.isArray(list) || list.length === 0) {
        hideSuggestions();
        return;
    }

    visible = list.slice(0, 9);
    suggestions.innerHTML = '';

    visible.forEach((command, index) => {
        const row = document.createElement('div');
        row.className = 'suggestion';

        if (index === selected) {
            row.classList.add('selected');
        }

        const top = document.createElement('div');
        top.className = 'top';

        const commandName = document.createElement('span');
        commandName.className = 'cmd';
        commandName.textContent = `/${command.command}`;

        const description = document.createElement('span');
        description.className = 'desc';
        description.textContent = command.description || '';

        const usage = document.createElement('div');
        usage.className = 'usage';
        usage.textContent = command.usage || '';

        top.append(commandName, description);
        row.append(top, usage);

        row.addEventListener('click', () => {
            input.value = `/${command.command} `;
            input.focus();
            resetHistoryNavigation();
            hideSuggestions();
        });

        suggestions.appendChild(row);
    });

    suggestions.style.display = 'block';
}

function hideSuggestions() {
    suggestions.style.display = 'none';
    suggestions.innerHTML = '';
    visible = [];
    selected = 0;
}

function updateSelection() {
    const rows = [...suggestions.querySelectorAll('.suggestion')];

    rows.forEach((row, index) => {
        row.classList.toggle('selected', index === selected);
    });

    if (rows[selected]) {
        rows[selected].scrollIntoView({ block: 'nearest' });
    }
}

function chooseSelected() {
    const command = visible[selected];

    if (!command) return;

    input.value = `/${command.command} `;
    input.focus();
    resetHistoryNavigation();
    hideSuggestions();
}
