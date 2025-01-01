// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-irregular-whitespace */

import { describe, it, assert } from 'vitest'

import { htmlCleanup } from '../htmlCleanup.ts'

// htmlCleanup
describe('htmlCleanup utility', () => {
  it('removes comments', () => {
    const source = '<div><!--test comment--><a href="test">test</a></div>'
    const should = '<div><a href="test">test</a></div>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('keeps text as is', () => {
    const source = 'some link to somewhere'
    const should = 'some link to somewhere'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('keeps lists as is', () => {
    const source = '<li>a</li><li>b</li>'
    const should = '<li>a</li><li>b</li>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('keeps link', () => {
    const source = '<p><a href="some_link">some link to somewhere</a></p>'
    const should = '<p><a href="some_link">some link to somewhere</a></p>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  // This is done on backend
  // source = '<div><p id="123" data-id="abc">some link to somewhere</p></div>'
  // should = '<p>some link to somewhere</p>'
  // result = htmlCleanup(source)
  // assert.equal(result, should, source)

  it('removes "small" tag', () => {
    const source = '<small>some link to somewhere</small>'
    const should = 'some link to somewhere'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('removes "time" tag', () => {
    const source = '<div><time>some link to somewhere</time></a>'
    const should = '<div>some link to somewhere</div>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('removes wrapper for several children', () => {
    const source = '<h1>some h1 for somewhere</h1><p><hr></p>'
    const should = '<h1>some h1 for somewhere</h1><p></p><hr><p></p>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('removes wrapper for "br"', () => {
    const source = '<div><br></div>'
    const should = '<p></p>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('keeps inner div', () => {
    const source = '<div class="xxx"><br></div>'
    const should = '<p class="xxx"></p>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('removes form', () => {
    const source = '<form class="xxx">test 123</form>'
    const should = 'test 123'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('removes subform', () => {
    const source = '<form class="xxx">test 123</form> some other value'
    const should = 'test 123 some other value'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('removes form tag and input', () => {
    const source =
      '<form class="xxx">test 123</form> some other value<input value="should not be shown">'
    const should = 'test 123 some other value'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('removes svg', () => {
    const source =
      '<font size="3" color="red">This is some text!</font><svg><use xlink:href="assets/images/icons.svg#icon-status"></svg>'
    const should = '<font size="3" color="red">This is some text!</font>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('removes "w" an "o" tags', () => {
    const source =
      '<p>some link to somewhere from word<w:sdt>abc</w:sdt></p><o:p></o:p></a>'
    // should = "<div><p>some link to somewhere from wordabc</p></div>"
    const should = '<p>some link to somewhere from wordabc</p>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('clears external tags', () => {
    const source =
      '<div><div><label for="Ticket_888344_group_id">Gruppe <span>*</span></label></div><div><div></div></div><div><div><span></span><span></span></div></div><div><div><label for="Ticket_888344_owner_id">Besitzer <span></span></label></div><div><div></div></div></div><div><div><div><svg><use xlink:href="http://localhost:3000/assets/images/icons.svg#icon-arrow-down"></use></svg></div><span></span><span></span></div></div><div><div>    <label for="Ticket_888344_state_id">Status <span>*</span></label></div></div></div>\n'
    const should =
      '<div><div>Gruppe <span>*</span></div><div><div></div></div><div><div><span></span><span></span></div></div><div><div>Besitzer <span></span></div><div><div></div></div></div><div><div><div></div><span></span><span></span></div></div><div><div>    Status <span>*</span></div></div></div>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('clears html head', () => {
    const source =
      '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">\n<html>\n<head>\n  <meta http-equiv="content-type" content="text/html; charset=utf-8"/>\n  <title></title>\n  <meta name="generator" content="LibreOffice 4.4.7.2 (MacOSX)"/>\n  <style type="text/css">\n    @page { margin: 0.79in }\n    p { margin-bottom: 0.1in; line-height: 120% }\n    a:link { so-language: zxx }\n  </style>\n</head>\n<body lang="en-US" dir="ltr">\n<p align="center" style="margin-bottom: 0in; line-height: 100%">1.\nGehe a<b>uf </b><b>https://www.pfe</b>rdiathek.ge</p>\n<p align="center" style="margin-bottom: 0in; line-height: 100%"><br/>\n\n</p>\n<p align="center" style="margin-bottom: 0in; line-height: 100%">2.\nMel<font color="#800000">de Dich mit folgende</font> Zugangsdaten an:</p>\n<p align="center" style="margin-bottom: 0in; line-height: 100%">Benutzer:\nme@xxx.net</p>\n<p align="center" style="margin-bottom: 0in; line-height: 100%">Passwort:\nxxx.</p>\n</body>\n</html>'
    const should =
      '<p align="center" style="margin-bottom: 0in; line-height: 100%">1.\nGehe a<b>uf </b><b>https://www.pfe</b>rdiathek.ge</p><p align="center" style="margin-bottom: 0in; line-height: 100%"></p><p align="center" style="margin-bottom: 0in; line-height: 100%">2.\nMel<font color="#800000">de Dich mit folgende</font> Zugangsdaten an:</p><p align="center" style="margin-bottom: 0in; line-height: 100%">Benutzer:\nme@xxx.net</p><p align="center" style="margin-bottom: 0in; line-height: 100%">Passwort:\nxxx.</p>\n'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('clears table', () => {
    const source =
      '<table bgcolor="green" aaa="1"><thead><tr><th colspan="2" abc="a">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>'
    const should =
      '<table bgcolor="green" aaa="1"><thead><tr><th colspan="2" abc="a">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  it('clears lists and new lines', () => {
    const source = `<div>Wir führen eine (Produktiv-) Freshdesk Migratione für hosted Kunden kostenfrei durch.</div><div><br></div><div>
<h3>Ablauf der Migration:</h3>
<div><ul>
<li>Abstimmung zum Projektablauf und Zeitplan</li>
<li>Produktivmigration zum gewünschten Zeitpunkt. Dabei werden folgende Attribute übertragen:<br><ul>
<li>Companys</li>
<li>User (Agenten+Kontakte)</li>
<li>Gruppen</li>
<li>Tickets (inkl. aller Artikel und Anhänge)</li>
<li>Individuelle Felder (User, Ticket, Company)</li>
<li>Time-Accounting der Tickets (sofern im Freshdesk-Plan enthalten)</li>
</ul>
</li>
<li>Nach erfolgreicher Migration ist direkt die Anmeldung durch den hinterlegten User möglich<br>
</li>
<li>Passwörter von anderen Usern können nicht mit übergeben werden, daher müssen sich weitere User über Standard Authentifizierung, wie z.B. der Passwort-zurücksetzen Funktion am System anmelden</li>
<li>Zum gewünschten Zeitpunkt werden die Postfächer aktiviert (durch uns)</li>
<li>Manuelle Zuweisung des Postfaches (durch den Kunden)</li>
</ul></div>
</div><h3>Weiteres Vorgehen:</h3><div>Während der Migration kommt es zu einer Downtime, in der keine Tickets erstellt werden können. Die Downtime kann vorab abgeschätzt werden. Dafür brauchen wir folgende Informationen:<br><ul>
<li>Name des bisherigen Freshdesk Plans (davon ist die Anzahl der Tickets abhängig, die über die API abgefragt werden können)</li>
<li>Ticketanzahl gesamt</li>
</ul>
<div>Außerdem benötigen wir:</div>
</div><div><ul>
<li>Email-Adresse und den API-Token eines Benutzers, der Zugriff auf alle relevanten Tickets hat</li>
<li>Name der Zammad hosted Instanz</li>
<li>gewünschter Zeitpunkt der Produktivmigration</li>
<li>gewünschter Zeitpunkt für die Aktivierung des Zammad-Postfaches</li>
</ul></div><div>Sobald wir alle Informationen haben, werden wir Ihnen die Downtime zukommen lassen und danach mit dem Kunden alle weiteren Termine abstimmen.<br>
</div><div><br></div><h3>zusätzliche Testmigration?</h3><div>Möchte der Kunde auf Nummer Sicher gehen und eine Testmigration durchführen, damit er genügend Zeit hat sich mit dem Zammad System und den dazugehörigen Einstellungen vertraut machen? Das ist kein Problem! Über den kostenfreien Migrationsservice in Form der oben beschriebenen Produktiv-Migration hinaus, bieten wir eine zusätzliche Testmigration für 1.450€ an. Dieses Migrationspaket beinhaltet eine zusätzliche Testmigration sowie eventuelle Anpassungswünsche (vgl. Checkliste OTRS Migration). Je nachdem, ob sich weitere Anpassungswünsche aus der Checkliste ergeben, können die Kosten steigen.</div>`
    const should =
      '<div>Wir führen eine (Produktiv-) Freshdesk Migratione für hosted Kunden&nbsp;kostenfrei&nbsp;durch.</div><p></p><div><h3>Ablauf der Migration:</h3><div><ul><li>Abstimmung zum Projektablauf und Zeitplan</li><li>Produktivmigration zum gewünschten Zeitpunkt. Dabei werden folgende Attribute übertragen:<ul><li>Companys</li><li>User (Agenten+Kontakte)</li><li>Gruppen</li><li>Tickets (inkl. aller Artikel und Anhänge)</li><li>Individuelle Felder (User, Ticket, Company)</li><li>Time-Accounting der Tickets (sofern im Freshdesk-Plan enthalten)</li></ul></li><li>Nach erfolgreicher Migration ist direkt die Anmeldung durch den hinterlegten User möglich</li><li>Passwörter von anderen Usern können nicht mit übergeben werden, daher müssen sich weitere User über Standard Authentifizierung, wie z.B. der Passwort-zurücksetzen Funktion am System anmelden</li><li>Zum gewünschten Zeitpunkt werden die Postfächer aktiviert (durch uns)</li><li>Manuelle Zuweisung des Postfaches (durch den Kunden)</li></ul></div></div><h3>Weiteres Vorgehen:</h3><div>Während der Migration kommt es zu einer Downtime, in der keine Tickets erstellt werden können. Die Downtime kann vorab abgeschätzt werden. Dafür brauchen wir folgende Informationen:<ul><li>Name des bisherigen Freshdesk Plans (davon ist die Anzahl der Tickets abhängig, die über die API abgefragt werden können)</li><li>Ticketanzahl gesamt</li></ul><div>Außerdem benötigen wir:</div></div><div><ul><li>Email-Adresse und den API-Token eines Benutzers, der Zugriff auf alle relevanten Tickets hat</li><li>Name der Zammad hosted Instanz</li><li>gewünschter Zeitpunkt der Produktivmigration</li><li>gewünschter Zeitpunkt für die Aktivierung des Zammad-Postfaches</li></ul></div><div>Sobald wir alle Informationen haben, werden wir Ihnen die Downtime zukommen lassen und danach mit dem Kunden alle weiteren Termine abstimmen.</div><p></p><h3>zusätzliche Testmigration?</h3><div>Möchte der Kunde auf Nummer Sicher gehen und eine Testmigration durchführen, damit er genügend Zeit hat sich mit dem Zammad System und den dazugehörigen Einstellungen vertraut machen? Das ist kein Problem! Über den kostenfreien Migrationsservice in Form der oben beschriebenen Produktiv-Migration hinaus, bieten wir eine zusätzliche Testmigration für 1.450€ an. Dieses&nbsp;Migrationspaket&nbsp;beinhaltet eine zusätzliche Testmigration sowie eventuelle Anpassungswünsche (vgl. Checkliste OTRS Migration). Je nachdem, ob sich weitere Anpassungswünsche aus der Checkliste ergeben, können die Kosten steigen.</div>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  test("doesn't remove extra break lines", () => {
    const source = `<p>This is a note<br><br></p><blockquote type="cite">
<p>On .+, #{article.created_by.fullname} wrote:</p>\n<p><br></p>
<p>#{article.body}</p>\n
</blockquote><p><br></p>`
    const should =
      '<p>This is a note<br></p><blockquote type="cite"><p>On .+, #{article.created_by.fullname} wrote:</p><p><br></p><p>#{article.body}</p></blockquote><p><br></p>'
    const result = htmlCleanup(source)
    assert.equal(result, should, source)
  })

  // strip out browser-inserted (broken) link (see https://github.com/zammad/zammad/issues/2019)
  // should not be possible in the new tech stack
  // source =
  //   '<div><a href="https://example.com/#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">test</a></div>'
  // should =
  //   '<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">test</a>'
  // result = htmlCleanup(source)
  // assert.equal(result, should, source)

  // this is done on the backend now
  // source =
  //   '<table bgcolor="green" aaa="1" style="color: red"><thead><tr style="margin-top: 10px"><th colspan="2" abc="a" style="margin-top: 12px">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>'
  // should =
  //   '<table bgcolor="green" style="color:red;"><thead><tr style="margin-top:10px;"><th colspan="2" style="margin-top:12px;">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>'
  // result = htmlCleanup(source)
  // result.get(0).outerHTML
  // // equal(result.get(0).outerHTML, should, source) / string order is different on browsers
  // assert.equal(result.first().attr('bgcolor'), 'green')
  // assert.equal(result.first().attr('style'), 'color:red;')
  // assert.equal(result.first().attr('aaa'), undefined)
  // assert.equal(result.find('tr').first().attr('style'), 'margin-top:10px;')
  // assert.equal(result.find('th').first().attr('colspan'), '2')
  // assert.equal(result.find('th').first().attr('abc'), undefined)
  // assert.equal(result.find('th').first().attr('style'), 'margin-top:12px;')

  // source =
  //   '<table bgcolor="green" aaa="1" style="color:red; display: none;"><thead><tr><th colspan="2" abc="a">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>'
  // should =
  //   '<table bgcolor="green" style="color:red;"><thead><tr><th colspan="2">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>'
  // result = htmlCleanup(source)
  // // equal(result.get(0).outerHTML, should, source) / string order is different on browsers
  // assert.equal(result.first().attr('bgcolor'), 'green')
  // assert.equal(result.first().attr('style'), 'color:red;')
  // assert.equal(result.first().attr('aaa'), undefined)
  // assert.equal(result.find('tr').first().attr('style'), undefined)
  // assert.equal(result.find('th').first().attr('colspan'), '2')
  // assert.equal(result.find('th').first().attr('abc'), undefined)
  // assert.equal(result.find('th').first().attr('style'), undefined)

  // https://github.com/zammad/zammad/issues/4445
  // source =
  //   '<meta charset=\'utf-8\'><span style="color: rgb(219, 219, 220);">This is a black font colour with white background</span>'
  // should = '<span>This is a black font colour with white background</span>'
  // result = htmlCleanup(source)
  // assert.equal(result, should, source)

  // source =
  //   '<meta charset=\'utf-8\'><div class="article-content" style="box-sizing: border-box; color: rgb(219, 219, 220); position: relative; z-index: 1; padding: 0px 55px;"><div class="bubble-gap" style="box-sizing: border-box;"><div class="internal-border" style="box-sizing: border-box; padding: 5px; border-radius: 5px; margin: -5px;"><div class="textBubble" style="box-sizing: border-box; padding: 10px 20px; background: var(--background-article-customer); border-radius: 2px; border-color: var(--border-article-customer); box-shadow: none; position: relative;"><div class="textBubble-content" id="article-content-4" data-id="4" style="box-sizing: border-box; overflow: hidden; position: relative;"><div class="richtext-content" style="box-sizing: border-box;"><div style="box-sizing: border-box;">This is a black font colour with white background</div></div></div></div></div></div></div>'
  // should =
  //   '<div><div><div><div><div id="article-content-4"><div><div>This is a black font colour with white background</div></div></div></div></div></div></div>'
  // result = htmlCleanup(source)
  // assert.equal(result, should, source)
})
