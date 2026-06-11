/* Copyright (c) 2026 Cappysan. All rights reserved. */

Ext.define('AS.ARC.apps.certbot.core', {
    extend: 'Ext.util.Observable',

    apiUrl: AS.ARC.util.getUserAppsPath() + 'cappysan-certbot/' + 'certbot.cgi',

    constructor: function (config) {
        Ext.apply(this, config);
        this.callParent();
        this.init(config);
    },

    init: function () {
        var fn = this;

        fn.win = fn.desktop.createWindow({
            app:       fn.app,
            id:        fn.id,
            itemId:    fn.id,
            title:     '<div class="as-header" style="background-image:url(' + AS.ARC.util.fixDc('/apps/cappysan-certbot/images/icon-app-task.png') + ');background-position:50%;background-repeat:no-repeat;"></div><div class="as-header-text">Certbot</div>',

            width:     700,
            height:    500,
            minWidth:  700,
            minHeight: 500,
            resizable: true,
            border:    false,
            layout:    'fit',
            items:     [fn.getMainPanel()],
            listeners: {
                afterrender: function (win) {
                    win.header.items.items[1].hide();
                    fn.navGrid.getSelectionModel().select(0);
                }
            }
        });
    },

    getNavGrid: function () {
        var fn = this;

        fn.navGrid = Ext.create('Ext.grid.Panel', {
            itemId: 'navGrid',
            store: Ext.create('Ext.data.ArrayStore', {
                fields: ['title', 'tabId'],
                data: [
                    [_S('CERTBOT', 'TAB_CERTIFICATE'), 'certificate'],
                    [_S('CERTBOT', 'TAB_SETTINGS'),    'settings']
                ]
            }),
            hideHeaders: true,
            height:      '100%',
            border:      false,
            columns: [{
                flex:     1,
                renderer: function (v, metadata, record) {
                    var icons = {
                        certificate: AS.ARC.util.fixDc('apps/settings/images/icon-fn-certificate.png'),
                        settings:    AS.ARC.util.fixDc('/apps/cappysan-certbot/images/icon-app.png')
                    };
                    var iconUrl = icons[record.data.tabId] || icons.certificate;
                    return '<div class="fn-block">' +
                           '<div class="fn-icon" style="background-image:url(' + iconUrl + ');background-repeat:no-repeat;background-position:center center;background-size:contain;"></div>' +
                           '<div class="fn-title" style="width:130px;opacity:1;">' + record.data.title + '</div>' +
                           '<div class="x-clear"></div>' +
                           '</div>';
                }
            }],
            listeners: {
                selectionchange: function (model, selections) {
                    if (selections.length > 0) {
                        fn.switchTab(selections[0].get('tabId'));
                    }
                }
            }
        });

        return fn.navGrid;
    },

    switchTab: function (tabId) {
        var fn        = this,
            cardPanel = fn.win.down('#cardPanel');

        fn.win.el.mask(_S('COMMON', 'LOADING'));

        AS.ARC.ajax({
            url:    AS.ARC.util.getApiUrlWithSid(fn.apiUrl, { act: 'get', tab: tabId }),
            method: 'post',
            success: function (json) {
                fn.win.el.unmask();
                cardPanel.removeAll();
                if (tabId === 'certificate') { fn.renderCertificateTab(cardPanel, json); }
                if (tabId === 'settings')    { fn.renderSettingsTab(cardPanel, json); }
            },
            failure: function (json) {
                fn.win.el.unmask();
                AS.ARC.util.showMsgWindow({ 5000: _S('COMMON', 'SESSION_TIMEOUT') }, json, fn.win);
            }
        });
    },

    /* ── Certificate tab ────────────────────────────────────────────────── */
    renderCertificateTab: function (cardPanel, json) {
        var labelWidth = 100;

        // Compute expiry note
        var expiryNote = '';
        if (json.not_after) {
            var expDate = new Date(json.not_after);
            var now     = new Date();
            var diffMs  = expDate - now;
            if (!isNaN(diffMs)) {
                if (diffMs <= 0) {
                    expiryNote = 'Certificate is expired.';
                } else {
                    var days = Math.floor(diffMs / 86400000);
                    expiryNote = 'Expires in ' + days + ' day' + (days !== 1 ? 's' : '');
                }
            }
        }

        var items = [{
            xtype:      'textfield',
            fieldLabel: AS.ARC.util.fontToBold('Issuer'),
            labelWidth: labelWidth,
            readOnly:   true,
            cls:        'persistence-readonly',
            value:      json.issuer || ''
        }, {
            xtype:      'textfield',
            fieldLabel: AS.ARC.util.fontToBold('CN'),
            labelWidth: labelWidth,
            readOnly:   true,
            cls:        'persistence-readonly',
            value:      json.cn || ''
        }, {
            xtype:      'textfield',
            fieldLabel: AS.ARC.util.fontToBold('Not Before'),
            labelWidth: labelWidth,
            readOnly:   true,
            cls:        'persistence-readonly',
            value:      json.not_before || ''
        }, {
            xtype:      'textfield',
            fieldLabel: AS.ARC.util.fontToBold('Not After'),
            labelWidth: labelWidth,
            readOnly:   true,
            cls:        'persistence-readonly',
            value:      json.not_after || ''
        }];

        if (expiryNote) {
            items.push({
                xtype: 'displayfield',
                value: expiryNote
            });
        }

        items.push({
            xtype: 'displayfield',
            value: '<a href="/portal/downloads/' + (json.token || '') + '-certificates.zip" target="_blank">Download certificate</a>'
        });

        items.push({
            xtype: 'displayfield',
            value: 'If not already the case, this certbot certificate must be configured as the default certificate in the Settings, <a href="#" onclick="AS.ARC.core.openApp(\'app-settings\', \'certificate\'); return false;">Certificate Manager</a> tab.'
        });

        cardPanel.add(Ext.create('Ext.panel.Panel', {
            cls:    'as-page-panel app-cappysan-certbot',
            border: false,
            layout: 'anchor',
            defaults: { anchor: '100%' },
            items: [{
                xtype:    'fieldset',
                title:    'Certificate',
                defaults: { anchor: '100%', msgTarget: AS.ARC.config.msgTarget },
                items:    items
            }]
        }));
    },

    /* ── Settings tab ───────────────────────────────────────────────────── */
    renderSettingsTab: function (cardPanel, json) {
        var fn         = this,
            labelWidth = 140;

        var ovhItems = [];
        if ((json.provider || 'ovh') === 'ovh') {
            ovhItems = [{
                xtype:  'displayfield',
                itemId: 'ovhTokenLink',
                value:  '<a href="https://auth.eu.ovhcloud.com/api/createToken" target="_blank">Create OVH API token</a>'
            }, {
                xtype:      'combo',
                fieldLabel: AS.ARC.util.fontToBold('Endpoint'),
                labelWidth: labelWidth,
                itemId:     'ovhEndpoint',
                store:      ['ovh-eu'],
                editable:   false,
                value:      json.ovh_endpoint || 'ovh-eu',
                anchor:     '100%'
            }, {
                xtype:      'textfield',
                fieldLabel: AS.ARC.util.fontToBold('Application Key'),
                labelWidth: labelWidth,
                itemId:     'ovhAppKey',
                value:      json.ovh_application_key || '',
                anchor:     '100%'
            }, {
                xtype:      'textfield',
                fieldLabel: AS.ARC.util.fontToBold('Application Secret'),
                labelWidth: labelWidth,
                itemId:     'ovhAppSecret',
                value:      json.ovh_application_secret || '',
                anchor:     '100%'
            }, {
                xtype:      'textfield',
                fieldLabel: AS.ARC.util.fontToBold('Consumer Key'),
                labelWidth: labelWidth,
                itemId:     'ovhConsumerKey',
                value:      json.ovh_consumer_key || '',
                anchor:     '100%'
            }];
        }

        cardPanel.add(Ext.create('Ext.panel.Panel', {
            cls:        'as-page-panel app-cappysan-certbot',
            border:     false,
            layout:     'anchor',
            autoScroll: true,
            defaults:   { anchor: '100%' },
            items: [{
                xtype:    'fieldset',
                title:    _S('CERTBOT', 'SECTION_SETTINGS'),
                defaults: { anchor: '100%', msgTarget: AS.ARC.config.msgTarget },
                items: [{
                    xtype:      'textfield',
                    fieldLabel: AS.ARC.util.fontToBold(_S('CERTBOT', 'LABEL_DOMAINS')),
                    labelWidth: labelWidth,
                    itemId:     'settingsDomains',
                    anchor:     '100%',
                    value:      json.domains || ''
                }, {
                    xtype:      'combo',
                    fieldLabel: AS.ARC.util.fontToBold(_S('CERTBOT', 'LABEL_PROVIDER')),
                    labelWidth: labelWidth,
                    itemId:     'settingsProvider',
                    store:      ['ovh'],
                    editable:   false,
                    value:      json.provider || 'ovh',
                    anchor:     '100%'
                }]
            }, {
                xtype:    'fieldset',
                title:    _S('CERTBOT', 'SECTION_CREDENTIALS'),
                itemId:   'credentialsFieldset',
                defaults: { anchor: '100%', msgTarget: AS.ARC.config.msgTarget },
                items:    ovhItems
            }, {
                xtype:    'fieldset',
                title:    _S('CERTBOT', 'SECTION_ADVANCED'),
                defaults: { anchor: '100%', msgTarget: AS.ARC.config.msgTarget },
                items: [{
                    xtype:      'textfield',
                    fieldLabel: AS.ARC.util.fontToBold(_S('CERTBOT', 'LABEL_CMDLINE')),
                    labelWidth: labelWidth,
                    itemId:     'settingsCmdline',
                    emptyText:  json.default_cmdline || '',
                    value:      json.cmdline || '',
                    anchor:     '100%'
                }, {
                    xtype: 'displayfield',
                    value: '<a href="#" onclick="AS.ARC.core.openApp(\'app-systemInformation\', \'log\'); return false;">View certbot logs</a>'
                }]
            }],
            dockedItems: [{
                xtype: 'toolbar',
                dock:  'bottom',
                ui:    'footer',
                items: [
                    { xtype: 'component', flex: 1 },
                    {
                        xtype:   'button',
                        text:    _S('CERTBOT', 'BTN_RENEW'),
                        cls:     'certbot-btn-white',
                        handler: function () { fn.renewCertificate(); }
                    },
                    {
                        xtype:   'button',
                        text:    _S('COMMON', 'APPLY'),
                        handler: function () { fn.saveSettingsTab(); }
                    }
                ]
            }]
        }));
    },

    saveSettingsTab: function () {
        var fn          = this,
            domains     = fn.win.down('#settingsDomains'),
            provider    = fn.win.down('#settingsProvider'),
            cmdline     = fn.win.down('#settingsCmdline'),
            ovhEndpoint = fn.win.down('#ovhEndpoint'),
            ovhAppKey   = fn.win.down('#ovhAppKey'),
            ovhAppSecret= fn.win.down('#ovhAppSecret'),
            ovhConsumerKey = fn.win.down('#ovhConsumerKey');

        fn.win.el.mask(_S('COMMON', 'APPLYING'));
        AS.ARC.ajax({
            url:    AS.ARC.util.getApiUrlWithSid(fn.apiUrl, { act: 'set', tab: 'settings' }),
            method: 'post',
            params: {
                domains:              domains        ? domains.getValue()        : '',
                provider:             provider       ? provider.getValue()       : '',
                cmdline:              cmdline        ? cmdline.getValue()        : '',
                ovh_endpoint:         ovhEndpoint    ? ovhEndpoint.getValue()    : '',
                ovh_application_key:  ovhAppKey      ? ovhAppKey.getValue()      : '',
                ovh_application_secret: ovhAppSecret ? ovhAppSecret.getValue()   : '',
                ovh_consumer_key:     ovhConsumerKey ? ovhConsumerKey.getValue() : ''
            },
            success: function () {
                fn.win.el.unmask();
                fn.switchTab('settings');
            },
            failure: function (json) {
                fn.win.el.unmask();
                AS.ARC.util.showMsgWindow({ 5000: _S('COMMON', 'SESSION_TIMEOUT') }, json, fn.win);
            }
        });
    },

    renewCertificate: function () {
        var fn          = this,
            domains     = fn.win.down('#settingsDomains'),
            provider    = fn.win.down('#settingsProvider'),
            cmdline     = fn.win.down('#settingsCmdline'),
            ovhEndpoint = fn.win.down('#ovhEndpoint'),
            ovhAppKey   = fn.win.down('#ovhAppKey'),
            ovhAppSecret= fn.win.down('#ovhAppSecret'),
            ovhConsumerKey = fn.win.down('#ovhConsumerKey');

        fn.win.el.mask(_S('COMMON', 'APPLYING'));
        AS.ARC.ajax({
            url:    AS.ARC.util.getApiUrlWithSid(fn.apiUrl, { act: 'set', tab: 'settings' }),
            method: 'post',
            params: {
                domains:                domains        ? domains.getValue()        : '',
                provider:               provider       ? provider.getValue()       : '',
                cmdline:                cmdline        ? cmdline.getValue()        : '',
                ovh_endpoint:           ovhEndpoint    ? ovhEndpoint.getValue()    : '',
                ovh_application_key:    ovhAppKey      ? ovhAppKey.getValue()      : '',
                ovh_application_secret: ovhAppSecret   ? ovhAppSecret.getValue()   : '',
                ovh_consumer_key:       ovhConsumerKey ? ovhConsumerKey.getValue() : ''
            },
            success: function () {
                AS.ARC.ajax({
                    url:    AS.ARC.util.getApiUrlWithSid(fn.apiUrl, { act: 'renew' }),
                    method: 'post',
                    success: function () { fn.win.el.unmask(); },
                    failure: function (json) {
                        fn.win.el.unmask();
                        AS.ARC.util.showMsgWindow({ 5000: _S('COMMON', 'SESSION_TIMEOUT') }, json, fn.win);
                    }
                });
            },
            failure: function (json) {
                fn.win.el.unmask();
                AS.ARC.util.showMsgWindow({ 5000: _S('COMMON', 'SESSION_TIMEOUT') }, json, fn.win);
            }
        });
    },

    /* ── Layout ─────────────────────────────────────────────────────────── */
    getMainPanel: function () {
        var fn = this;

        return Ext.create('Ext.panel.Panel', {
            itemId: 'main',
            border: false,
            layout: 'border',
            items: [{
                region: 'west',
                itemId: 'westPanel',
                cls:    'as-selector-panel',
                border: false,
                width:  150,
                layout: 'fit',
                items:  [fn.getNavGrid()]
            }, {
                region: 'center',
                xtype:  'panel',
                itemId: 'cardPanel',
                border: false,
                layout: 'fit'
            }]
        });
    }
});

Ext.define('AS.ARC.apps.certbot.main', {
    extend:     'AS.ARC._appBase',
    appTag:     'cappysan-certbot',
    title:      'Certbot',
    appMaxNum:  1,
    appOpenNum: 0,
    appIsReady: true,
    appWins:    [],

    createWindow: function () {
        var desktop = this.core.getDesktop(),
            app     = this;

        if ((this.appOpenNum === this.appMaxNum) || !this.appIsReady) {
            this.appWins[0].show();
            return;
        }

        this.appIsReady = false;

        var certbot = Ext.create('AS.ARC.apps.certbot.core', {
            app:     this,
            desktop: desktop,
            id:      this.id + '-' + Ext.id()
        });

        certbot.win.on('render', function () {
            app.appOpenNum++;
            app.appIsReady = true;
        });

        certbot.win.on('beforeclose', function () {
            app.appOpenNum--;
            app.appIsReady = true;
            app.appWins.pop();
        });

        certbot.win.show();
        this.appWins.push(certbot.win);
        return certbot.win;
    }
});
