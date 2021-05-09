fx_version 'adamant'

game 'gta5'

description 'ESX Mechanic Job'

version '1.1.0'

client_scripts {
	'@es_extended/locale.lua',
	'locales/en.lua',
	'config.lua',
	'custom_cars.lua',
	'client/*.lua'
}

server_scripts {
	'@es_extended/locale.lua',
	'@mysql-async/lib/MySQL.lua',
	'locales/en.lua',
	'config.lua',
	'custom_cars.lua',
	'server/main.lua'
}

dependencies {
	'es_extended',
	'master_society',
	'esx_billing'
}
