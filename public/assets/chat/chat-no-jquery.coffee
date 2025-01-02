do(window) ->

  scripts = document.getElementsByTagName('script')

  # search for script to get protocol and hostname for ws connection
  myScript = scripts[scripts.length - 1]
  scriptProtocol = window.location.protocol.replace(':', '') # set default protocol
  if myScript && myScript.src
    scriptHost = myScript.src.match('.*://([^:/]*).*')[1]
    scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1]

  # Define the plugin class
  class Core
    defaults:
      debug: false

    constructor: (options) ->
      @options = {}

      for key, value of @defaults
        @options[key] = value

      for key, value of options
        @options[key] = value

  class Base extends Core
    constructor: (options) ->
      super(options)

      @log = new Log(debug: @options.debug, logPrefix: @options.logPrefix || @logPrefix)

  class Log extends Core
    debug: (items...) =>
      return if !@options.debug
      @log('debug', items)

    notice: (items...) =>
      @log('notice', items)

    error: (items...) =>
      @log('error', items)

    log: (level, items) =>
      items.unshift('||')
      items.unshift(level)
      items.unshift(@options.logPrefix)
      console.log.apply console, items

      return if !@options.debug
      logString = ''
      for item in items
        logString += ' '
        if typeof item is 'object'
          logString += JSON.stringify(item)
        else if item && item.toString
          logString += item.toString()
        else
          logString += item
      element = document.querySelector('.js-chatLogDisplay')
      if element
        element.innerHTML = '<div>' + logString + '</div>' + element.innerHTML

  class Timeout extends Base
    timeoutStartedAt: null
    logPrefix: 'timeout'
    defaults:
      debug: false
      timeout: 4
      timeoutIntervallCheck: 0.5

    start: =>
      @stop()
      timeoutStartedAt = new Date
      check = =>
        timeLeft = new Date - new Date(timeoutStartedAt.getTime() + @options.timeout * 1000 * 60)
        @log.debug "Timeout check for #{@options.timeout} minutes (left #{timeLeft/1000} sec.)"#, new Date
        return if timeLeft < 0
        @stop()
        @options.callback()
      @log.debug "Start timeout in #{@options.timeout} minutes"#, new Date
      @intervallId = setInterval(check, @options.timeoutIntervallCheck * 1000 * 60)

    stop: =>
      return if !@intervallId
      @log.debug "Stop timeout of #{@options.timeout} minutes"#, new Date
      clearInterval(@intervallId)

  class Io extends Base
    logPrefix: 'io'

    set: (params) =>
      for key, value of params
        @options[key] = value

    connect: =>
      @log.debug "Connecting to #{@options.host}"
      @ws = new window.WebSocket("#{@options.host}")
      @ws.onopen = (e) =>
        @log.debug 'onOpen', e
        @options.onOpen(e)
        @ping()

      @ws.onmessage = (e) =>
        pipes = JSON.parse(e.data)
        @log.debug 'onMessage', e.data
        for pipe in pipes
          if pipe.event is 'pong'
            @ping()
        if @options.onMessage
          @options.onMessage(pipes)

      @ws.onclose = (e) =>
        @log.debug 'close websocket connection', e
        if @pingDelayId
          clearTimeout(@pingDelayId)
        if @manualClose
          @log.debug 'manual close, onClose callback'
          @manualClose = false
          if @options.onClose
            @options.onClose(e)
        else
          @log.debug 'error close, onError callback'
          if @options.onError
            @options.onError('Connection lost...')

      @ws.onerror = (e) =>
        @log.debug 'onError', e
        if @options.onError
          @options.onError(e)

    close: =>
      @log.debug 'close websocket manually'
      @manualClose = true
      @ws.close()

    reconnect: =>
      @log.debug 'reconnect'
      @close()
      @connect()

    send: (event, data = {}) =>
      @log.debug 'send', event, data
      msg = JSON.stringify
        event: event
        data: data
      @ws.send msg

    ping: =>
      localPing = =>
        @send('ping')
      @pingDelayId = setTimeout(localPing, 29000)

  class ZammadChat extends Base
    defaults:
      chatId: undefined
      show: true
      target: document.querySelector('body')
      host: ''
      debug: false
      flat: false
      lang: undefined
      cssAutoload: true
      cssUrl: undefined
      fontSize: undefined
      buttonClass: 'open-zammad-chat'
      inactiveClass: 'is-inactive'
      title: '<strong>Chat</strong> with us!'
      scrollHint: 'Scroll down to see new messages'
      idleTimeout: 6
      idleTimeoutIntervallCheck: 0.5
      inactiveTimeout: 8
      inactiveTimeoutIntervallCheck: 0.5
      waitingListTimeout: 4
      waitingListTimeoutIntervallCheck: 0.5
      # Callbacks
      onReady: undefined
      onCloseAnimationEnd: undefined
      onError: undefined
      onOpenAnimationEnd: undefined
      onConnectionReestablished: undefined
      onSessionClosed: undefined
      onConnectionEstablished: undefined
      onCssLoaded: undefined

    logPrefix: 'chat'
    _messageCount: 0
    isOpen: false
    blinkOnlineInterval: null
    stopBlinOnlineStateTimeout: null
    showTimeEveryXMinutes: 2
    lastTimestamp: null
    lastAddedType: null
    inputDisabled: false
    inputTimeout: null
    isTyping: false
    state: 'offline'
    initialQueueDelay: 10000
    translations:
    # ZAMMAD_TRANSLATIONS_START
      'cs':
        '<strong>Chat</strong> with us!': '<strong>Chatujte</strong> s námi!'
        'All colleagues are busy.': 'Všichni kolegové jsou vytíženi.'
        'Chat closed by %s': '%s ukončil konverzaci'
        'Compose your message…': 'Napište svou zprávu…'
        'Connecting': 'Připojování'
        'Connection lost': 'Připojení ztraceno'
        'Connection re-established': 'Připojení obnoveno'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Srolujte dolů pro zobrazení nových zpráv'
        'Send': 'Odeslat'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Jelikož jste nereagovali v posledních %s minutách, vaše konverzace byla uzavřena.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Jelikož jste nereagovali v posledních %s minutách, vaše konverzace s <strong>%s</strong> byla uzavřena.'
        'Start new conversation': 'Zahájit novou konverzaci'
        'Today': 'Dnes'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Omlouváme se, že musíte čekat déle, než je vhodné pro získání slotu. Prosím, zkuste to později, případně nám napište e-mail. Děkujeme!'
        'You are on waiting list position <strong>%s</strong>.': 'Jste <strong>%s</strong>. v pořadí na čekací listině.'
      'da':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med os!'
        'All colleagues are busy.': 'Alle medarbejdere er optaget.'
        'Chat closed by %s': 'Chat lukket af %s'
        'Compose your message…': 'Skriv din besked…'
        'Connecting': 'Forbinder'
        'Connection lost': 'Forbindelse mistet'
        'Connection re-established': 'Forbindelse genoprettet'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Scroll ned for at se nye beskeder'
        'Send': 'Afsend'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': ''
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': ''
        'Start new conversation': 'Start en ny samtale'
        'Today': 'I dag'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': ''
        'You are on waiting list position <strong>%s</strong>.': 'Du er i kø som nummer <strong>%s</strong>.'
      'de':
        '<strong>Chat</strong> with us!': '<strong>Chatte</strong> mit uns!'
        'All colleagues are busy.': 'Alle Kollegen sind beschäftigt.'
        'Chat closed by %s': 'Chat von %s geschlossen'
        'Compose your message…': 'Verfassen Sie Ihre Nachricht…'
        'Connecting': 'Verbinde'
        'Connection lost': 'Verbindung verloren'
        'Connection re-established': 'Verbindung wieder aufgebaut'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Nach unten scrollen um neue Nachrichten zu sehen'
        'Send': 'Senden'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Da Sie innerhalb der letzten %s Minuten nicht reagiert haben, wurde Ihre Unterhaltung geschlossen.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Da Sie innerhalb der letzten %s Minuten nicht reagiert haben, wurde Ihre Unterhaltung mit <strong>%s</strong> geschlossen.'
        'Start new conversation': 'Neue Unterhaltung starten'
        'Today': 'Heute'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Entschuldigung, es dauert länger als erwartet einen freien Platz zu bekommen. Versuchen Sie es später erneut oder senden Sie uns eine E-Mail. Vielen Dank!'
        'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste auf Position <strong>%s</strong>.'
      'es':
        '<strong>Chat</strong> with us!': '<strong>Chatee</strong> con nosotros!'
        'All colleagues are busy.': 'Todos los colegas están ocupados.'
        'Chat closed by %s': 'Chat cerrado por %s'
        'Compose your message…': 'Escribe tu mensaje…'
        'Connecting': 'Conectando'
        'Connection lost': 'Conexión perdida'
        'Connection re-established': 'Conexión reestablecida'
        'Offline': 'Desconectado'
        'Online': 'En línea'
        'Scroll down to see new messages': 'Desplace hacia abajo para ver nuevos mensajes'
        'Send': 'Enviar'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Debido a que usted no ha respondido en los últimos %s minutos, su conversación se ha cerrado.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Debido a que usted no ha respondido en los últimos %s minutos, su conversación con <strong>%s</strong> se ha cerrado.'
        'Start new conversation': 'Iniciar nueva conversación'
        'Today': 'Hoy'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Lo sentimos, estamos tardando más de lo esperado para asignar un agente. Inténtelo de nuevo más tarde o envíenos un correo electrónico. ¡Gracias!'
        'You are on waiting list position <strong>%s</strong>.': 'Usted está en la posición <strong>%s</strong> de la lista de espera.'
      'fr':
        '<strong>Chat</strong> with us!': '<strong>Chattez</strong> avec nous !'
        'All colleagues are busy.': 'Tous les agents sont occupés.'
        'Chat closed by %s': 'Chat fermé par %s'
        'Compose your message…': 'Écrivez votre message…'
        'Connecting': 'Connexion'
        'Connection lost': 'Connexion perdue'
        'Connection re-established': 'Connexion ré-établie'
        'Offline': 'Hors-ligne'
        'Online': 'En ligne'
        'Scroll down to see new messages': 'Défiler vers le bas pour voir les nouveaux messages'
        'Send': 'Envoyer'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Sans réponse de votre part depuis %s minutes, votre conservation a été fermée.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Sans réponse de votre part depuis %s minutes, votre conversation avec <strong>%s</strong> a été fermée.'
        'Start new conversation': 'Démarrer une nouvelle conversation'
        'Today': 'Aujourd\'hui'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Nous sommes désolés, trouver un agent disponible prend plus de temps que prévu. Réessayez plus tard ou envoyez-nous un mail. Merci !'
        'You are on waiting list position <strong>%s</strong>.': 'Vous êtes actuellement en position <strong>%s</strong> dans la file d\'attente.'
      'hr':
        '<strong>Chat</strong> with us!': '<strong>Čavrljajte</strong> sa nama!'
        'All colleagues are busy.': 'Svi agenti su zauzeti.'
        'Chat closed by %s': '%s zatvara chat'
        'Compose your message…': 'Sastavite poruku…'
        'Connecting': 'Povezivanje'
        'Connection lost': 'Veza prekinuta'
        'Connection re-established': 'Veza je ponovno uspostavljena'
        'Offline': 'Odsutan'
        'Online': 'Dostupan(a)'
        'Scroll down to see new messages': 'Pomaknite se prema dolje da biste vidjeli nove poruke'
        'Send': 'Pošalji'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Budući da niste odgovorili u posljednjih %s minuta, Vaš je razgovor zatvoren.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Budući da niste odgovorili u posljednjih %s minuta, Vaš je razgovor s <strong>%</strong>s zatvoren.'
        'Start new conversation': 'Započni novi razgovor'
        'Today': 'Danas'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Oprostite, traje duže nego inače za dobiti slobodan termin. Molimo, pokušajte ponovno kasnije ili nam pošaljite e-mail. Hvala!'
        'You are on waiting list position <strong>%s</strong>.': 'Nalazite se u redu čekanja na poziciji <strong>%s</strong>.'
      'hu':
        '<strong>Chat</strong> with us!': '<strong>Csevegjen</strong> velünk!'
        'All colleagues are busy.': 'Minden munkatársunk foglalt.'
        'Chat closed by %s': 'A csevegés %s által lezárva'
        'Compose your message…': 'Fogalmazza meg üzenetét…'
        'Connecting': 'Csatlakozás'
        'Connection lost': 'A kapcsolat megszakadt'
        'Connection re-established': 'A kapcsolat helyreállt'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Görgessen lefelé az új üzenetek megtekintéséhez'
        'Send': 'Küldés'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Mivel az elmúlt %s percben nem válaszolt, a beszélgetése lezárásra került.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Mivel az elmúlt %s percben nem válaszolt, <strong>%s</strong> munkatársunkkal folytatott beszélgetését lezártuk.'
        'Start new conversation': 'Új beszélgetés indítása'
        'Today': 'Ma'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Sajnáljuk, hogy a vártnál hosszabb ideig tart a helyfoglalás. Kérjük, próbálja meg később újra, vagy küldjön nekünk egy e-mailt. Köszönjük!'
        'You are on waiting list position <strong>%s</strong>.': 'Ön a várólistán a <strong>%s</strong> helyen szerepel.'
      'it':
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> con noi!'
        'All colleagues are busy.': 'Tutti i colleghi sono occupati.'
        'Chat closed by %s': 'Chat chiusa da %s'
        'Compose your message…': 'Scrivi il tuo messaggio…'
        'Connecting': 'Connessione in corso'
        'Connection lost': 'Connessione persa'
        'Connection re-established': 'Connessione ristabilita'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Scorri verso il basso per vedere i nuovi messaggi'
        'Send': 'Invia'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Dato che non hai risposto negli ultimi %s minuti, la conversazione è stata chiusa.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Dato che non hai risposto negli ultimi %s minuti, la conversazione con <strong>%s</strong> è stata chiusa.'
        'Start new conversation': 'Avvia una nuova chat'
        'Today': 'Oggi'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Siamo spiacenti, ci vuole più tempo del previsto per ottenere uno spazio libero. Riprova più tardi o inviaci un\'e-mail. Grazie!'
        'You are on waiting list position <strong>%s</strong>.': 'Sei alla posizione <strong>%s</strong> della lista di attesa.'
      'lt':
        '<strong>Chat</strong> with us!': '<strong>Kalbėkitės</strong> su mumis!'
        'All colleagues are busy.': 'Visi kolegos užimti.'
        'Chat closed by %s': '%s uždarė pokalbį'
        'Compose your message…': 'Rašykite žinutę…'
        'Connecting': 'Jungiamasi'
        'Connection lost': 'Dingo ryšys'
        'Connection re-established': 'Ryšys atnaujintas'
        'Offline': 'Atsijungęs'
        'Online': 'Prisijungęs'
        'Scroll down to see new messages': 'Naujos žinutės žemiau'
        'Send': 'Siųsti'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Jūsų pokalbis buvo uždarytas, nes nieko neatsakėte per %s minučių.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Jūsų pokalbis su <strong>%s</strong> buvo uždarytas, nes nieko neatsakėte per %s minučių.'
        'Start new conversation': 'Pradėti naują pokalbį'
        'Today': 'Šiandien'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Atsiprašome, kad tenka laukti atskymo. Bandykite vėliau arba rašykite el. paštu. Ačiū!'
        'You are on waiting list position <strong>%s</strong>.': 'Esate <strong>%s</strong> eilėje.'
      'nl':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> met ons!'
        'All colleagues are busy.': 'Alle collega\'s zijn bezet.'
        'Chat closed by %s': 'Chat gesloten door %s'
        'Compose your message…': 'Stel je bericht op…'
        'Connecting': 'Verbinden'
        'Connection lost': 'Verbinding verbroken'
        'Connection re-established': 'Verbinding hersteld'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Scroll naar beneden om nieuwe tickets te bekijken'
        'Send': 'Verstuur'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'De chat is afgesloten omdat je de laatste %s minuten niet hebt gereageerd.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Je chat met <strong>%s</strong> is afgesloten omdat je niet hebt gereageerd in de laatste %s minuten.'
        'Start new conversation': 'Nieuw gesprek starten'
        'Today': 'Vandaag'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Het spijt ons, het duurt langer dan verwacht om een chat te starten. Probeer het later nog eens of stuur ons een e-mail. Bedankt!'
        'You are on waiting list position <strong>%s</strong>.': 'Je bevindt zich op wachtlijstpositie <strong>%s</strong>.'
      'pl':
        '<strong>Chat</strong> with us!': '<strong>Czatuj</strong> z nami!'
        'All colleagues are busy.': 'Wszyscy agenci są zajęci.'
        'Chat closed by %s': 'Chat zamknięty przez %s'
        'Compose your message…': 'Skomponuj swoją wiadomość…'
        'Connecting': 'Łączenie'
        'Connection lost': 'Utracono połączenie'
        'Connection re-established': 'Ponowne nawiązanie połączenia'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Skroluj w dół, aby zobaczyć wiadomości'
        'Send': 'Wyślij'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa została zamknięta.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa z <strong>%s</strong> została zamknięta.'
        'Start new conversation': 'Rozpocznij nową rozmowę'
        'Today': 'Dzisiaj'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Przepraszamy, znalezienie wolnego konsultanta zajmuje więcej czasu niż oczekiwano. Spróbuj ponownie później lub wyślij nam e-mail. Dziękujemy!'
        'You are on waiting list position <strong>%s</strong>.': 'Jesteś na pozycji listy oczekujących <strong>%s</strong>.'
      'pt-br':
        '<strong>Chat</strong> with us!': '<strong>Converse</strong> conosco!'
        'All colleagues are busy.': 'Nossos atendentes estão ocupados.'
        'Chat closed by %s': 'Chat encerrado por %s'
        'Compose your message…': 'Escreva sua mensagem…'
        'Connecting': 'Conectando'
        'Connection lost': 'Conexão perdida'
        'Connection re-established': 'Conexão restabelecida'
        'Offline': 'Desconectado'
        'Online': 'Online'
        'Scroll down to see new messages': 'Rolar para baixo para ver novas mensagems'
        'Send': 'Enviar'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Como você não respondeu nos últimos %s minutos, sua conversa foi encerrada.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Como você não respondeu nos últimos %s minutos, sua conversa com <strong>%s</strong> foi encerrada.'
        'Start new conversation': 'Iniciar uma nova conversa'
        'Today': 'Hoje'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Lamentamos, está demorando mais do que o esperado para conseguir uma vaga. Tente novamente mais tarde ou envie-nos um e-mail. Obrigado!'
        'You are on waiting list position <strong>%s</strong>.': 'Você está na posição <strong>%s</strong> da lista de espera.'
      'ro':
        '<strong>Chat</strong> with us!': '<strong>Comunică</strong> cu noi!'
        'All colleagues are busy.': 'Toți colegii sunt ocupați momentan.'
        'Chat closed by %s': 'Chat închis de către %s'
        'Compose your message…': 'Compune-ți mesajul…'
        'Connecting': 'Se conectează'
        'Connection lost': 'Conexiune pierdută'
        'Connection re-established': 'Conexiune restabilită'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Derulați în jos pentru a vedea mesajele noi'
        'Send': 'Trimite'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Deoarece nu ai răspuns în ultimele %s minute, conversația ta a fost închisă.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Deoarece nu ai răspuns în ultimele %s minute, conversația ta cu <strong>%s</strong> a fost închisă.'
        'Start new conversation': 'Începe o conversație nouă'
        'Today': 'Azi'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Ne pare rău, durează mai mult decât ne așteptam să obținem un loc. Te rugăm să încerci din nou mai târziu sau să ne trimiți un email. Mulțumim!'
        'You are on waiting list position <strong>%s</strong>.': 'Aveți poziția <strong>%s</strong> în lista de așteptare.'
      'ru':
        '<strong>Chat</strong> with us!': '<strong>Напишите</strong> нам!'
        'All colleagues are busy.': 'Все коллеги заняты.'
        'Chat closed by %s': 'Чат закрыт %s'
        'Compose your message…': 'Составьте сообщение…'
        'Connecting': 'Подключение'
        'Connection lost': 'Подключение потеряно'
        'Connection re-established': 'Подключение восстановлено'
        'Offline': 'Оффлайн'
        'Online': 'В сети'
        'Scroll down to see new messages': 'Прокрутите вниз, чтобы увидеть новые сообщения'
        'Send': 'Отправить'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Поскольку Вы не ответили в течение последних %s минут, Ваш разговор был закрыт.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Поскольку Вы не ответили в течение последних %s минут, Ваш разговор с <strong>%s</strong> был закрыт.'
        'Start new conversation': 'Начать новый разговор'
        'Today': 'Сегодня'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Извините, получение свободного слота занимает больше времени, чем ожидалось. Пожалуйста, повторите попытку позже или отправьте нам электронное письмо. Благодарим Вас!'
        'You are on waiting list position <strong>%s</strong>.': 'Вы находитесь в списке ожидания <strong>%s</strong>.'
      'sk':
        '<strong>Chat</strong> with us!': '<strong>Napíšte</strong> nám cez chat!'
        'All colleagues are busy.': 'Všetci kolegovia sú zaneprázdnení.'
        'Chat closed by %s': 'Chat zatvoril(a) %s'
        'Compose your message…': 'Napíšte vašu správu…'
        'Connecting': 'Pripája sa'
        'Connection lost': 'Spojenie prerušené'
        'Connection re-established': 'Pripojenie obnovené'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Posuňte sa nadol, aby ste videli nové správy'
        'Send': 'Odoslať'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Keďže ste neodpovedali v posledných %s minútach, vaša konverzácia bola uzavretá.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Keďže ste v posledných %s minútach neodpovedali, vaša konverzácia s <strong>%s</strong> bola ukončená.'
        'Start new conversation': 'Začať novú konverzáciu'
        'Today': 'Dnes'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Je nám ľúto, že získanie slotu trvá dlhšie, než sme očakávali. Skúste to prosím neskôr alebo nám pošlite e-mail. Ďakujeme!'
        'You are on waiting list position <strong>%s</strong>.': 'Na čakacej listine ste na pozícii <strong>%s</strong>.'
      'sr':
        '<strong>Chat</strong> with us!': '<strong>Ћаскајте</strong> са нама!'
        'All colleagues are busy.': 'Све колеге су заузете.'
        'Chat closed by %s': 'Ћаскање затворено од стране %s'
        'Compose your message…': 'Напишите поруку…'
        'Connecting': 'Повезивање'
        'Connection lost': 'Веза је изгубљена'
        'Connection re-established': 'Веза је поново успостављена'
        'Offline': 'Одсутан(а)'
        'Online': 'Доступан(а)'
        'Scroll down to see new messages': 'Скролујте на доле за нове поруке'
        'Send': 'Пошаљи'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Пошто нисте одговорили у последњих %s минут(a), ваш разговор је завршен.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Пошто нисте одговорили у последњих %s минут(a), ваш разговор са <strong>%s</strong> је завршен.'
        'Start new conversation': 'Започни нови разговор'
        'Today': 'Данас'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Жао нам је, добијање празног термина траје дуже од очекиваног. Молимо покушајте поново касније или нам пошаљите имејл поруку. Хвала вам!'
        'You are on waiting list position <strong>%s</strong>.': 'Ви сте тренутно <strong>%s.</strong> у реду за чекање.'
      'sr-latn-rs':
        '<strong>Chat</strong> with us!': '<strong>Ćaskajte</strong> sa nama!'
        'All colleagues are busy.': 'Sve kolege su zauzete.'
        'Chat closed by %s': 'Ćaskanje zatvoreno od strane %s'
        'Compose your message…': 'Napišite poruku…'
        'Connecting': 'Povezivanje'
        'Connection lost': 'Veza je izgubljena'
        'Connection re-established': 'Veza je ponovo uspostavljena'
        'Offline': 'Odsutan(a)'
        'Online': 'Dostupan(a)'
        'Scroll down to see new messages': 'Skrolujte na dole za nove poruke'
        'Send': 'Pošalji'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Pošto niste odgovorili u poslednjih %s minut(a), vaš razgovor je završen.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Pošto niste odgovorili u poslednjih %s minut(a), vaš razgovor sa <strong>%s</strong> je završen.'
        'Start new conversation': 'Započni novi razgovor'
        'Today': 'Danas'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Žao nam je, dobijanje praznog termina traje duže od očekivanog. Molimo pokušajte ponovo kasnije ili nam pošaljite imejl poruku. Hvala vam!'
        'You are on waiting list position <strong>%s</strong>.': 'Vi ste trenutno <strong>%s.</strong> u redu za čekanje.'
      'sv':
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> med oss!'
        'All colleagues are busy.': 'Alla kollegor är upptagna.'
        'Chat closed by %s': 'Chatt stängd av %s'
        'Compose your message…': 'Skriv ditt meddelande …'
        'Connecting': 'Ansluter'
        'Connection lost': 'Anslutningen försvann'
        'Connection re-established': 'Anslutningen återupprättas'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Bläddra ner för att se nya meddelanden'
        'Send': 'Skicka'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Din chatt avslutades då du inte svarade inom %s minuter.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Chatten stängdes eftersom du inte svarat inom %s minuter i din konversation med <strong>%s</strong>.'
        'Start new conversation': 'Starta ny konversation'
        'Today': 'Idag'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Det tar tyvärr längre tid än förväntat att få en ledig plats. Försök igen senare eller skicka ett mejl till oss. Tack!'
        'You are on waiting list position <strong>%s</strong>.': 'Du är på väntelistan som position <strong>%s</strong>.'
      'zh-cn':
        '<strong>Chat</strong> with us!': '发起<strong>即时对话</strong>!'
        'All colleagues are busy.': '所有同事都很忙。'
        'Chat closed by %s': '对话已被 %s 关闭'
        'Compose your message…': '编辑您的信息…'
        'Connecting': '连接中'
        'Connection lost': '连接丢失'
        'Connection re-established': '正在重新建立连接'
        'Offline': '离线'
        'Online': '在线'
        'Scroll down to see new messages': '向下滚动以查看新消息'
        'Send': '发送'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': '"由于您超过 %s 分钟没有任何回复'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': '"由于您超过 %s 分钟没有回复'
        'Start new conversation': '开始新的会话'
        'Today': '今天'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': ''
        'You are on waiting list position <strong>%s</strong>.': '您目前的等候位置是第 <strong>%s</strong> 位.'
    # ZAMMAD_TRANSLATIONS_END
    sessionId: undefined
    scrolledToBottom: true
    scrollSnapTolerance: 10
    richTextFormatKey:
      66: true # b
      73: true # i
      85: true # u
      83: true # s

    T: (string, items...) =>
      if @options.lang && @options.lang isnt 'en'
        if !@translations[@options.lang]
          @log.notice "Translation '#{@options.lang}' needed!"
        else
          translations = @translations[@options.lang]
          if !translations[string]
            @log.notice "Translation needed for '#{string}'"
          string = translations[string] || string
      if items
        for item in items
          string = string.replace(/%s/, item)
      string

    view: (name) =>
      return (options) =>
        if !options
          options = {}

        options.T = @T
        options.background = @options.background
        options.flat = @options.flat
        options.fontSize = @options.fontSize
        return window.zammadChatTemplates[name](options)

    constructor: (options) ->
      super(options)

      # jQuery migration
      if typeof jQuery != 'undefined' && @options.target instanceof jQuery
        @log.notice 'Chat: target option is a jQuery object. jQuery is not a requirement for the chat any more.'
        @options.target = @options.target.get(0)

      # fullscreen
      @isFullscreen = (window.matchMedia and window.matchMedia('(max-width: 768px)').matches)
      @scrollRoot = @getScrollRoot()

      # check prerequisites
      if !window.WebSocket or !sessionStorage
        @state = 'unsupported'
        @log.notice 'Chat: Browser not supported!'
        return
      if !@options.chatId
        @state = 'unsupported'
        @log.error 'Chat: need chatId as option!'
        return

      # detect language
      if !@options.lang
        @options.lang = document.documentElement.getAttribute('lang')
      if @options.lang
        if !@translations[@options.lang]
          @log.debug "lang: No #{@options.lang} found, try first two letters"
          @options.lang = @options.lang.replace(/-.+?$/, '') # replace "-xx" of xx-xx
        @log.debug "lang: #{@options.lang}"

      # detect host
      @detectHost() if !@options.host

      @loadCss()

      @io = new Io(@options)
      @io.set(
        onOpen: @render
        onClose: @onWebSocketClose
        onMessage: @onWebSocketMessage
        onError: @onError
      )

      @io.connect()

    getScrollRoot: ->
      return document.scrollingElement if 'scrollingElement' of document
      html = document.documentElement
      start = parseInt(html.pageYOffset, 10)
      html.pageYOffset = start + 1
      end = parseInt(html.pageYOffset, 10)
      html.pageYOffset = start
      return if end > start then html else document.body

    render: =>
      if !@el || !document.querySelector('.zammad-chat')
        @renderBase()

      # disable open button
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.classList.add @options.inactiveClass

      @setAgentOnlineState 'online'

      @log.debug 'widget rendered'

      @startTimeoutObservers()
      @idleTimeout.start()

      # get current chat status
      @sessionId = sessionStorage.getItem('sessionId')
      @send 'chat_status_customer',
        session_id: @sessionId
        url: window.location.href

    renderBase: ->
      @el.remove() if @el
      @options.target.insertAdjacentHTML('beforeend', @view('chat')(
        title: @options.title,
        scrollHint: @options.scrollHint
      ))
      @el = @options.target.querySelector('.zammad-chat')
      @input = @el.querySelector('.zammad-chat-input')
      @body = @el.querySelector('.zammad-chat-body')

      # start bindings
      @el.querySelector('.js-chat-open').addEventListener('click', @open)
      @el.querySelector('.js-chat-toggle').addEventListener('click', @toggle)
      @el.querySelector('.js-chat-status').addEventListener('click', @stopPropagation)
      @el.querySelector('.zammad-chat-controls').addEventListener('submit', @onSubmit)
      @body.addEventListener('scroll', @detectScrolledtoBottom)
      @el.querySelector('.zammad-scroll-hint').addEventListener('click', @onScrollHintClick)
      @input.addEventListener('keydown', @onKeydown)
      @input.addEventListener('input', @onInput)
      @input.addEventListener('paste', @onPaste)
      @input.addEventListener('drop', @onDrop)

      window.addEventListener('beforeunload', @onLeaveTemporary)
      window.addEventListener('hashchange', =>
        if @isOpen
          if @sessionId
            @send 'chat_session_notice',
              session_id: @sessionId
              message: window.location.href
          return
        @idleTimeout.start()
      )

    stopPropagation: (event) ->
      event.stopPropagation()

    onDrop: (e) =>
      e.stopPropagation()
      e.preventDefault()

      if window.dataTransfer # ie
        dataTransfer = window.dataTransfer
      else if e.dataTransfer # other browsers
        dataTransfer = e.dataTransfer
      else
        throw 'No clipboardData support'

      x = e.clientX
      y = e.clientY
      file = dataTransfer.files[0]

      # look for images
      if file.type.match('image.*')
        reader = new FileReader()
        reader.onload = (e) =>
          # Insert the image at the carat
          insert = (dataUrl, width) =>

            # adapt image if we are on retina devices
            if @isRetina()
              width = width / 2

            result = dataUrl
            img = new Image()
            img.style.width = '100%'
            img.style.maxWidth = width + 'px'
            img.src = result

            if document.caretPositionFromPoint
              pos = document.caretPositionFromPoint(x, y)
              range = document.createRange()
              range.setStart(pos.offsetNode, pos.offset)
              range.collapse()
              range.insertNode(img)
            else if document.caretRangeFromPoint
              range = document.caretRangeFromPoint(x, y)
              range.insertNode(img)
            else
              console.log('could not find carat')

          # resize if to big
          @resizeImage(e.target.result, 460, 'auto', 2, 'image/jpeg', 'auto', insert)
        reader.readAsDataURL(file)

    onPaste: (e) =>
      e.stopPropagation()
      e.preventDefault()

      if e.clipboardData
        clipboardData = e.clipboardData
      else if window.clipboardData
        clipboardData = window.clipboardData
      else if e.clipboardData
        clipboardData = e.clipboardData
      else
        throw 'No clipboardData support'

      imageInserted = false
      if clipboardData && clipboardData.items && clipboardData.items[0]
        item = clipboardData.items[0]
        if item.kind == 'file' && (item.type == 'image/png' || item.type == 'image/jpeg')
          imageFile = item.getAsFile()
          reader = new FileReader()

          reader.onload = (e) =>
            insert = (dataUrl, width) =>

              # adapt image if we are on retina devices
              if @isRetina()
                width = width / 2

              img = new Image()
              img.style.width = '100%'
              img.style.maxWidth = width + 'px'
              img.src = dataUrl
              document.execCommand('insertHTML', false, img)

            # resize if to big
            @resizeImage(e.target.result, 460, 'auto', 2, 'image/jpeg', 'auto', insert)

          reader.readAsDataURL(imageFile)
          imageInserted = true

      return if imageInserted

      # check existing + paste text for limit
      text = undefined
      docType = undefined
      try
        text = clipboardData.getData('text/html')
        docType = 'html'
        if !text || text.length is 0
          docType = 'text'
          text = clipboardData.getData('text/plain')
        if !text || text.length is 0
          docType = 'text2'
          text = clipboardData.getData('text')
      catch e
        console.log('Sorry, can\'t insert markup because browser is not supporting it.')
        docType = 'text3'
        text = clipboardData.getData('text')

      if docType is 'text' || docType is 'text2' || docType is 'text3'
        text = '<div>' + text.replace(/\n/g, '</div><div>') + '</div>'
        text = text.replace(/<div><\/div>/g, '<div><br></div>')
      console.log('p', docType, text)
      if docType is 'html'
        html = document.createElement('div')
        # can't log because might contain malicious content
        # @log.debug 'HTML clipboard', text
        sanitized = DOMPurify.sanitize(text)
        @log.debug 'sanitized HTML clipboard', sanitized
        html.innerHTML = sanitized
        match = false
        htmlTmp = text
        regex = new RegExp('<(/w|w)\:[A-Za-z]')
        if htmlTmp.match(regex)
          match = true
          htmlTmp = htmlTmp.replace(regex, '')
        regex = new RegExp('<(/o|o)\:[A-Za-z]')
        if htmlTmp.match(regex)
          match = true
          htmlTmp = htmlTmp.replace(regex, '')
        if match
          html = @wordFilter(html)
        #html

        for node in html.childNodes
          if node.nodeType == 8
            node.remove()

        # remove tags, keep content
        for node in html.querySelectorAll('a, font, small, time, form, label')
          node.outerHTML = node.innerHTML

        # replace tags with generic div
        # New type of the tag
        replacementTag = 'div';

        # Replace all x tags with the type of replacementTag
        for node in html.querySelectorAll('textarea')
          outer = node.outerHTML

          # Replace opening tag
          regex = new RegExp('<' + node.tagName, 'i')
          newTag = outer.replace(regex, '<' + replacementTag)

          # Replace closing tag
          regex = new RegExp('</' + node.tagName, 'i')
          newTag = newTag.replace(regex, '</' + replacementTag)

          node.outerHTML = newTag

        # remove tags & content
        for node in html.querySelectorAll('font, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset')
          node.remove()

        @removeAttributes(html)

        text = html.innerHTML

      # as fallback, insert html via pasteHtmlAtCaret (for IE 11 and lower)
      if docType is 'text3'
        @pasteHtmlAtCaret(text)
      else
        document.execCommand('insertHTML', false, text)
      true

    onKeydown: (e) =>
      # check for enter
      if not @inputDisabled and not e.shiftKey and e.keyCode is 13
        e.preventDefault()
        @sendMessage()

      richtTextControl = false
      if !e.altKey && !e.ctrlKey && e.metaKey
        richtTextControl = true
      else if !e.altKey && e.ctrlKey && !e.metaKey
        richtTextControl = true

      if richtTextControl && @richTextFormatKey[ e.keyCode ]
        e.preventDefault()
        if e.keyCode is 66
          document.execCommand('bold')
          return true
        if e.keyCode is 73
          document.execCommand('italic')
          return true
        if e.keyCode is 85
          document.execCommand('underline')
          return true
        if e.keyCode is 83
          document.execCommand('strikeThrough')
          return true

    send: (event, data = {}) =>
      data.chat_id = @options.chatId
      @io.send(event, data)

    onWebSocketMessage: (pipes) =>
      for pipe in pipes
        @log.debug 'ws:onmessage', pipe
        switch pipe.event
          when 'chat_error'
            @log.notice pipe.data
            if pipe.data && pipe.data.state is 'chat_disabled'
              @destroy(remove: true)
          when 'chat_session_message'
            return if pipe.data.self_written
            @receiveMessage pipe.data
          when 'chat_session_typing'
            return if pipe.data.self_written
            @onAgentTypingStart()
          when 'chat_session_start'
            @onConnectionEstablished pipe.data
          when 'chat_session_queue'
            @onQueueScreen pipe.data
          when 'chat_session_closed'
            @onSessionClosed pipe.data
          when 'chat_session_left'
            @onSessionClosed pipe.data
          when 'chat_status_customer'
            switch pipe.data.state
              when 'online'
                @sessionId = undefined

                if !@options.cssAutoload || @cssLoaded
                  @onReady()
                else
                  @socketReady = true
              when 'offline'
                @onError 'Zammad Chat: No agent online'
              when 'chat_disabled'
                @onError 'Zammad Chat: Chat is disabled'
              when 'no_seats_available'
                @onError "Zammad Chat: Too many clients in queue. Clients in queue: #{pipe.data.queue}"
              when 'reconnect'
                @onReopenSession pipe.data

    onReady: ->
      @log.debug 'widget ready for use'
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.addEventListener('click', @open)
        btn.classList.remove(@options.inactiveClass)

      @options.onReady?()

      if @options.show
        @show()

    onError: (message) =>
      @log.debug message
      @addStatus(message)
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.classList.add('zammad-chat-is-hidden')

      if @isOpen
        @disableInput()
        @destroy(remove: false)
      else
        @destroy(remove: true)

      @options.onError?(message)

    onReopenSession: (data) =>
      @log.debug 'old messages', data.session
      @inactiveTimeout.start()

      unfinishedMessage = sessionStorage.getItem 'unfinished_message'

      # rerender chat history
      if data.agent
        @onConnectionEstablished(data)

        for message in data.session
          @renderMessage
            message: message.content
            id: message.id
            from: if message.created_by_id then 'agent' else 'customer'

        if unfinishedMessage
          @input.innerHTML = unfinishedMessage

      # show wait list
      if data.position
        @onQueue data

      @show()
      @open()
      @scrollToBottom()

      if unfinishedMessage
        @input.focus()

    onInput: =>
      # remove unread-state from messages
      for message in @el.querySelectorAll('.zammad-chat-message--unread')
        message.classList.remove 'zammad-chat-message--unread'

      sessionStorage.setItem 'unfinished_message', @input.innerHTML

      @onTyping()

    onTyping: ->

      # send typing start event only every 1.5 seconds
      return if @isTyping && @isTyping > new Date(new Date().getTime() - 1500)
      @isTyping = new Date()
      @send 'chat_session_typing',
        session_id: @sessionId
      @inactiveTimeout.start()

    onSubmit: (event) =>
      event.preventDefault()
      @sendMessage()

    sendMessage: ->
      message = @input.innerHTML
      return if !message

      @inactiveTimeout.start()

      sessionStorage.removeItem 'unfinished_message'

      messageElement = @view('message')
        message: message
        from: 'customer'
        id: @_messageCount++
        unreadClass: ''

      @maybeAddTimestamp()

      # add message before message typing loader
      if @el.querySelector('.zammad-chat-message--typing')
        @lastAddedType = 'typing-placeholder'
        @el.querySelector('.zammad-chat-message--typing').insertAdjacentHTML('beforebegin', messageElement)
      else
        @lastAddedType = 'message--customer'
        @body.insertAdjacentHTML('beforeend', messageElement)

      @input.innerHTML = ''
      @scrollToBottom()

      # send message event
      @send 'chat_session_message',
        content: message
        id: @_messageCount
        session_id: @sessionId

    receiveMessage: (data) =>
      @inactiveTimeout.start()

      # hide writing indicator
      @onAgentTypingEnd()

      @maybeAddTimestamp()

      @renderMessage
        message: data.message.content
        id: data.id
        from: 'agent'

      @scrollToBottom showHint: true

    renderMessage: (data) =>
      @lastAddedType = "message--#{ data.from }"
      data.unreadClass = if document.hidden then ' zammad-chat-message--unread' else ''
      @body.insertAdjacentHTML('beforeend', @view('message')(data))

    open: =>
      if @isOpen
        @log.debug 'widget already open, block'
        return

      @isOpen = true
      @log.debug 'open widget'
      @show()

      if !@sessionId
        @showLoader()

      @el.classList.add 'zammad-chat-is-open'
      remainerHeight = @el.clientHeight - @el.querySelector('.zammad-chat-header').offsetHeight
      @el.style.transform = "translateY(#{remainerHeight}px)"
      # force redraw
      @el.clientHeight

      if !@sessionId
        @el.addEventListener 'transitionend', @onOpenAnimationEnd
        @el.classList.add 'zammad-chat--animate'
        # force redraw
        @el.clientHeight
        # start animation
        @el.style.transform = ''

        @send('chat_session_init'
          url: window.location.href
        )
      else
        @el.style.transform = ''
        @onOpenAnimationEnd()

    onOpenAnimationEnd: =>
      @el.removeEventListener 'transitionend', @onOpenAnimationEnd
      @el.classList.remove 'zammad-chat--animate'
      @idleTimeout.stop()

      if @isFullscreen
        @disableScrollOnRoot()
      @options.onOpenAnimationEnd?()

    sessionClose: =>
      # send close
      @send 'chat_session_close',
        session_id: @sessionId

      # stop timer
      @inactiveTimeout.stop()
      @waitingListTimeout.stop()

      # delete input store
      sessionStorage.removeItem 'unfinished_message'

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      @setSessionId undefined

    toggle: (event) =>
      if @isOpen
        @close(event)
      else
        @open(event)

    close: (event) =>
      if !@isOpen
        @log.debug 'can\'t close widget, it\'s not open'
        return
      if @initDelayId
        clearTimeout(@initDelayId)
      if @sessionId
        @log.debug 'session close before widget close'
        @sessionClose()

      @log.debug 'close widget'

      event.stopPropagation() if event

      if @isFullscreen
        @enableScrollOnRoot()

      # close window
      remainerHeight = @el.clientHeight - @el.querySelector('.zammad-chat-header').offsetHeight
      @el.addEventListener 'transitionend', @onCloseAnimationEnd
      @el.classList.add 'zammad-chat--animate'
      # force redraw
      document.offsetHeight
      # animate out
      @el.style.transform = "translateY(#{remainerHeight}px)"

    onCloseAnimationEnd: =>
      @el.removeEventListener 'transitionend', @onCloseAnimationEnd
      @el.classList.remove 'zammad-chat-is-open', 'zammad-chat--animate'
      @el.style.transform = ''

      @showLoader()
      @el.querySelector('.zammad-chat-welcome').classList.remove('zammad-chat-is-hidden')
      @el.querySelector('.zammad-chat-agent').classList.add('zammad-chat-is-hidden')
      @el.querySelector('.zammad-chat-agent-status').classList.add('zammad-chat-is-hidden')

      @isOpen = false
      @options.onCloseAnimationEnd?()

      @io.reconnect()

    onWebSocketClose: =>
      return if @isOpen
      if @el
        @el.classList.remove('zammad-chat-is-shown')
        @el.classList.remove('zammad-chat-is-loaded')

    show: ->
      return if @state is 'offline'

      @el.classList.add('zammad-chat-is-loaded')
      @el.classList.add('zammad-chat-is-shown')

    disableInput: ->
      @inputDisabled = true
      @input.setAttribute('contenteditable', false)
      @el.querySelector('.zammad-chat-send').disabled = true
      @io.close()

    enableInput: ->
      @inputDisabled = false
      @input.setAttribute('contenteditable', true)
      @el.querySelector('.zammad-chat-send').disabled = false

    hideModal: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = ''

    onQueueScreen: (data) =>
      @setSessionId data.session_id

      # delay initial queue position, show connecting first
      show = =>
        @onQueue data
        @waitingListTimeout.start()

      if @initialQueueDelay && !@onInitialQueueDelayId
        @onInitialQueueDelayId = setTimeout(show, @initialQueueDelay)
        return

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      # show queue position
      show()

    onQueue: (data) =>
      @log.notice 'onQueue', data.position
      @inQueue = true

      @el.querySelector('.zammad-chat-modal').innerHTML = @view('waiting')
        position: data.position

    onAgentTypingStart: =>
      if @stopTypingId
        clearTimeout(@stopTypingId)
      @stopTypingId = setTimeout(@onAgentTypingEnd, 3000)

      # never display two typing indicators
      return if @el.querySelector('.zammad-chat-message--typing')

      @maybeAddTimestamp()

      @body.insertAdjacentHTML('beforeend', @view('typingIndicator')())

      # only if typing indicator is shown
      return if !@isVisible(@el.querySelector('.zammad-chat-message--typing'), true)
      @scrollToBottom()

    onAgentTypingEnd: =>
      @el.querySelector('.zammad-chat-message--typing').remove() if @el.querySelector('.zammad-chat-message--typing')

    onLeaveTemporary: =>
      return if !@sessionId
      @send 'chat_session_leave_temporary',
        session_id: @sessionId

    maybeAddTimestamp: ->
      timestamp = Date.now()

      if !@lastTimestamp or (timestamp - @lastTimestamp) > @showTimeEveryXMinutes * 60000
        label = @T('Today')
        time = new Date().toTimeString().substr 0,5
        if @lastAddedType is 'timestamp'
          # update last time
          @updateLastTimestamp label, time
          @lastTimestamp = timestamp
        else
          # add new timestamp
          @body.insertAdjacentHTML 'beforeend', @view('timestamp')
            label: label
            time: time
          @lastTimestamp = timestamp
          @lastAddedType = 'timestamp'
          @scrollToBottom()

    updateLastTimestamp: (label, time) ->
      return if !@el
      timestamps = @el.querySelectorAll('.zammad-chat-body .zammad-chat-timestamp')
      return if !timestamps
      timestamps[timestamps.length - 1].outerHTML = @view('timestamp')
        label: label
        time: time

    addStatus: (status) ->
      return if !@el
      @maybeAddTimestamp()

      @body.insertAdjacentHTML 'beforeend', @view('status')
        status: status

      @scrollToBottom()

    detectScrolledtoBottom: =>
      scrollBottom = @body.scrollTop + @body.offsetHeight
      @scrolledToBottom = Math.abs(scrollBottom - @body.scrollHeight) <= @scrollSnapTolerance
      @el.querySelector('.zammad-scroll-hint').classList.add('is-hidden') if @scrolledToBottom

    showScrollHint: ->
      @el.querySelector('.zammad-scroll-hint').classList.remove('is-hidden')
      # compensate scroll
      @body.scrollTop = @body.scrollTop + @el.querySelector('.zammad-scroll-hint').offsetHeight

    onScrollHintClick: =>
      # animate scroll
      @body.scrollTo
        top: @body.scrollHeight
        behavior: 'smooth'

    scrollToBottom: ({ showHint } = { showHint: false }) ->
      if @scrolledToBottom
        @body.scrollTop = @body.scrollHeight
      else if showHint
        @showScrollHint()

    destroy: (params = {}) =>
      @log.debug 'destroy widget', params

      @setAgentOnlineState 'offline'

      if params.remove && @el
        @el.remove()

        # Remove button, because it can no longer be used.
        btn = document.querySelector(".#{ @options.buttonClass }")
        if btn
          btn.classList.add @options.inactiveClass
          btn.style.display = 'none';

      # stop all timer
      if @waitingListTimeout
        @waitingListTimeout.stop()
      if @inactiveTimeout
        @inactiveTimeout.stop()
      if @idleTimeout
        @idleTimeout.stop()

      # stop ws connection
      @io.close()

    reconnect: =>
      # set status to connecting
      @log.notice 'reconnecting'
      @disableInput()
      @lastAddedType = 'status'
      @setAgentOnlineState 'connecting'
      @addStatus @T('Connection lost')

    onConnectionReestablished: =>
      # set status back to online
      @lastAddedType = 'status'
      @setAgentOnlineState 'online'
      @addStatus @T('Connection re-established')
      @options.onConnectionReestablished?()

    onSessionClosed: (data) ->
      @addStatus @T('Chat closed by %s', data.realname)
      @disableInput()
      @setAgentOnlineState 'offline'
      @inactiveTimeout.stop()
      @options.onSessionClosed?(data)

    setSessionId: (id) =>
      @sessionId = id
      if id is undefined
        sessionStorage.removeItem 'sessionId'
      else
        sessionStorage.setItem 'sessionId', id

    onConnectionEstablished: (data) =>
      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout @onInitialQueueDelayId

      @inQueue = false
      if data.agent
        @agent = data.agent
      if data.session_id
        @setSessionId data.session_id

      # empty old messages
      @body.innerHTML = ''

      @el.querySelector('.zammad-chat-agent').innerHTML = @view('agent')
        agent: @agent

      @enableInput()

      @hideModal()
      @el.querySelector('.zammad-chat-welcome').classList.add('zammad-chat-is-hidden')
      @el.querySelector('.zammad-chat-agent').classList.remove('zammad-chat-is-hidden')
      @el.querySelector('.zammad-chat-agent-status').classList.remove('zammad-chat-is-hidden')

      @input.focus() if not @isFullscreen

      @setAgentOnlineState 'online'

      @waitingListTimeout.stop()
      @idleTimeout.stop()
      @inactiveTimeout.start()
      @options.onConnectionEstablished?(data)

    showCustomerTimeout: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('customer_timeout')
        agent: @agent.name
        delay: @options.inactiveTimeout
      @el.querySelector('.js-restart').addEventListener 'click', -> location.reload()
      @sessionClose()

    showWaitingListTimeout: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('waiting_list_timeout')
        delay: @options.watingListTimeout
      @el.querySelector('.js-restart').addEventListener 'click', -> location.reload()
      @sessionClose()

    showLoader: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('loader')()

    setAgentOnlineState: (state) =>
      @state = state
      return if !@el
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1)
      @el.querySelector('.zammad-chat-agent-status').dataset.status = state
      @el.querySelector('.zammad-chat-agent-status').textContent = @T(capitalizedState)

    detectHost: ->
      protocol = 'ws://'
      if scriptProtocol is 'https'
        protocol = 'wss://'
      @options.host = "#{ protocol }#{ scriptHost }/ws"

    loadCss: ->
      return if !@options.cssAutoload
      url = @options.cssUrl
      if !url
        url = @options.host
          .replace(/^wss/i, 'https')
          .replace(/^ws/i, 'http')
          .replace(/\/ws$/i, '') # WebSocket may run on example.com/ws path
        url += '/assets/chat/chat.css'

      @log.debug "load css from '#{url}'"
      styles = "@import url('#{url}');"
      newSS = document.createElement('link')
      newSS.onload = @onCssLoaded
      newSS.rel = 'stylesheet'
      newSS.href = 'data:text/css,' + escape(styles)
      document.getElementsByTagName('head')[0].appendChild(newSS)

    onCssLoaded: =>
      @cssLoaded = true
      if @socketReady
        @onReady()
      @options.onCssLoaded?()

    startTimeoutObservers: =>
      @idleTimeout = new Timeout(
        logPrefix: 'idleTimeout'
        debug: @options.debug
        timeout: @options.idleTimeout
        timeoutIntervallCheck: @options.idleTimeoutIntervallCheck
        callback: =>
          @log.debug 'Idle timeout reached, hide widget', new Date
          @destroy(remove: true)
      )
      @inactiveTimeout = new Timeout(
        logPrefix: 'inactiveTimeout'
        debug: @options.debug
        timeout: @options.inactiveTimeout
        timeoutIntervallCheck: @options.inactiveTimeoutIntervallCheck
        callback: =>
          @log.debug 'Inactive timeout reached, show timeout screen.', new Date
          @showCustomerTimeout()
          @destroy(remove: false)
      )
      @waitingListTimeout = new Timeout(
        logPrefix: 'waitingListTimeout'
        debug: @options.debug
        timeout: @options.waitingListTimeout
        timeoutIntervallCheck: @options.waitingListTimeoutIntervallCheck
        callback: =>
          @log.debug 'Waiting list timeout reached, show timeout screen.', new Date
          @showWaitingListTimeout()
          @destroy(remove: false)
      )

    disableScrollOnRoot: ->
      @rootScrollOffset = @scrollRoot.scrollTop
      @scrollRoot.style.overflow = 'hidden'
      @scrollRoot.style.position = 'fixed'

    enableScrollOnRoot: ->
      @scrollRoot.scrollTop = @rootScrollOffset
      @scrollRoot.style.overflow = ''
      @scrollRoot.style.position = ''

    # based on https://github.com/customd/jquery-visible/blob/master/jquery.visible.js
    # to have not dependency, port to coffeescript
    isVisible: (el, partial, hidden, direction) ->
      return if el.length < 1

      vpWidth    = window.innerWidth
      vpHeight   = window.innerHeight
      direction  = if direction then direction else 'both'
      clientSize = if hidden is true then t.offsetWidth * t.offsetHeight else true

      rec      = el.getBoundingClientRect()
      tViz     = rec.top >= 0 && rec.top    <  vpHeight
      bViz     = rec.bottom >  0 && rec.bottom <= vpHeight
      lViz     = rec.left >= 0 && rec.left   <  vpWidth
      rViz     = rec.right  >  0 && rec.right <= vpWidth
      vVisible = if partial then tViz || bViz else tViz && bViz
      hVisible = if partial then lViz || rViz else lViz && rViz

      if direction is 'both'
        return clientSize && vVisible && hVisible
      else if direction is 'vertical'
        return clientSize && vVisible
      else if direction is 'horizontal'
        return clientSize && hVisible

    isRetina: ->
      if window.matchMedia
        mq = window.matchMedia('only screen and (min--moz-device-pixel-ratio: 1.3), only screen and (-o-min-device-pixel-ratio: 2.6/2), only screen and (-webkit-min-device-pixel-ratio: 1.3), only screen  and (min-device-pixel-ratio: 1.3), only screen and (min-resolution: 1.3dppx)')
        return (mq && mq.matches || (window.devicePixelRatio > 1))
      false

    resizeImage: (dataURL, x = 'auto', y = 'auto', sizeFactor = 1, type, quallity, callback, force = true) ->

      # load image from data url
      imageObject = new Image()
      imageObject.onload = ->
        imageWidth  = imageObject.width
        imageHeight = imageObject.height
        console.log('ImageService', 'current size', imageWidth, imageHeight)
        if y is 'auto' && x is 'auto'
          x = imageWidth
          y = imageHeight

        # get auto dimensions
        if y is 'auto'
          factor = imageWidth / x
          y = imageHeight / factor

        if x is 'auto'
          factor = imageWidth / y
          x = imageHeight / factor

        # check if resize is needed
        resize = false
        if x < imageWidth || y < imageHeight
          resize = true
          x = x * sizeFactor
          y = y * sizeFactor
        else
          x = imageWidth
          y = imageHeight

        # create canvas and set dimensions
        canvas        = document.createElement('canvas')
        canvas.width  = x
        canvas.height = y

        # draw image on canvas and set image dimensions
        context = canvas.getContext('2d')
        context.drawImage(imageObject, 0, 0, x, y)

        # set quallity based on image size
        if quallity == 'auto'
          if x < 200 && y < 200
            quallity = 1
          else if x < 400 && y < 400
            quallity = 0.9
          else if x < 600 && y < 600
            quallity = 0.8
          else if x < 900 && y < 900
            quallity = 0.7
          else
            quallity = 0.6

        # execute callback with resized image
        newDataUrl = canvas.toDataURL(type, quallity)
        if resize
          console.log('ImageService', 'resize', x/sizeFactor, y/sizeFactor, quallity, (newDataUrl.length * 0.75)/1024/1024, 'in mb')
          callback(newDataUrl, x/sizeFactor, y/sizeFactor, true)
          return
        console.log('ImageService', 'no resize', x, y, quallity, (newDataUrl.length * 0.75)/1024/1024, 'in mb')
        callback(newDataUrl, x, y, false)

      # load image from data url
      imageObject.src = dataURL

    # taken from https://stackoverflow.com/questions/6690752/insert-html-at-caret-in-a-contenteditable-div/6691294#6691294
    pasteHtmlAtCaret: (html) ->
      sel = undefined
      range = undefined
      if window.getSelection
        sel = window.getSelection()
        if sel.getRangeAt && sel.rangeCount
          range = sel.getRangeAt(0)
          range.deleteContents()

          el = document.createElement('div')
          el.innerHTML = html
          frag = document.createDocumentFragment(node, lastNode)
          while node = el.firstChild
            lastNode = frag.appendChild(node)
          range.insertNode(frag)

          if lastNode
            range = range.cloneRange()
            range.setStartAfter(lastNode)
            range.collapse(true)
            sel.removeAllRanges()
            sel.addRange(range)
      else if document.selection && document.selection.type != 'Control'
        document.selection.createRange().pasteHTML(html)

    # (C) sbrin - https://github.com/sbrin
    # https://gist.github.com/sbrin/6801034
    wordFilter: (editor) ->
      content = editor.html()

      # Word comments like conditional comments etc
      content = content.replace(/<!--[\s\S]+?-->/gi, '')

      # Remove comments, scripts (e.g., msoShowComment), XML tag, VML content,
      # MS Office namespaced tags, and a few other tags
      content = content.replace(/<(!|script[^>]*>.*?<\/script(?=[>\s])|\/?(\?xml(:\w+)?|img|meta|link|style|\w:\w+)(?=[\s\/>]))[^>]*>/gi, '')

      # Convert <s> into <strike> for line-though
      content = content.replace(/<(\/?)s>/gi, '<$1strike>')

      # Replace nbsp entites to char since it's easier to handle
      # content = content.replace(/&nbsp;/gi, "\u00a0")
      content = content.replace(/&nbsp;/gi, ' ')

      # Convert <span style="mso-spacerun:yes">___</span> to string of alternating
      # breaking/non-breaking spaces of same length
      #content = content.replace(/<span\s+style\s*=\s*"\s*mso-spacerun\s*:\s*yes\s*;?\s*"\s*>([\s\u00a0]*)<\/span>/gi, (str, spaces) ->
      #  return (spaces.length > 0) ? spaces.replace(/./, " ").slice(Math.floor(spaces.length/2)).split("").join("\u00a0") : ''
      #)

      editor.innerHTML = content

      # Parse out list indent level for lists
      for p in editor.querySelectorAll('p')
        str = p.getAttribute('style')
        matches = /mso-list:\w+ \w+([0-9]+)/.exec(str)
        if matches
          p.dataset._listLevel = parseInt(matches[1], 10)

      # Parse Lists
      last_level = 0
      pnt = null
      for p in editor.querySelectorAll('p')
        cur_level = p.dataset._listLevel
        if cur_level != undefined
          txt = p.textContent
          list_tag = '<ul></ul>'
          if (/^\s*\w+\./.test(txt))
            matches = /([0-9])\./.exec(txt)
            if matches
              start = parseInt(matches[1], 10)
              list_tag = start>1 ? '<ol start="' + start + '"></ol>' : '<ol></ol>'
            else
              list_tag = '<ol></ol>'

          if cur_level > last_level
            if last_level == 0
              p.insertAdjacentHTML 'beforebegin', list_tag
              pnt = p.previousElementSibling
            else
            pnt.insertAdjacentHTML 'beforeend', list_tag

          if cur_level < last_level
            for i in [i..last_level-cur_level]
              pnt = pnt.parentNode

          p.querySelector('span:first').remove() if p.querySelector('span:first')
          pnt.insertAdjacentHTML 'beforeend', '<li>' + p.innerHTML + '</li>'
          p.remove()
          last_level = cur_level
        else
          last_level = 0

      el.removeAttribute('style') for el in editor.querySelectorAll('[style]')
      el.removeAttribute('align') for el in editor.querySelectorAll('[align]')
      el.outerHTML = el.innerHTML for el in editor.querySelectorAll('span')
      el.remove() for el in editor.querySelectorAll('span:empty')
      el.removeAttribute('class') for el in editor.querySelectorAll("[class^='Mso']")
      el.remove() for el in editor.querySelectorAll('p:empty')
      editor

    removeAttribute: (element) ->
      return if !element
      for att in element.attributes
        element.removeAttribute(att.name)

    removeAttributes: (html) =>
      for node in html.querySelectorAll('*')
        @removeAttribute node
      html

  window.ZammadChat = ZammadChat
