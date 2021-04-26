fx_version 'adamant'

game 'gta5'

description 'ESX Mechanic Job'

version '1.1.0'

client_scripts {
	'@es_extended/locale.lua',
	'locales/en.lua',
	'locales/es.lua',
	'locales/fi.lua',
	'locales/fr.lua',
	'locales/br.lua',
	'locales/sv.lua',
	'locales/pl.lua',
	'locales/nl.lua',
	'config.lua',
	'custom_cars.lua',
	'client/main.lua'
}

server_scripts {
	'@es_extended/locale.lua',
	'@mysql-async/lib/MySQL.lua',
	'locales/en.lua',
	'locales/es.lua',
	'locales/fi.lua',
	'locales/fr.lua',
	'locales/br.lua',
	'locales/sv.lua',
	'locales/pl.lua',
	'locales/nl.lua',
	'config.lua',
	'custom_cars.lua',
	'server/main.lua'
}

dependencies {
	'es_extended',
	'master_society',
	'esx_billing'
}
