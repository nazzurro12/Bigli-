extends RefCounted
class_name DFLore

const ERAS = {
	0: "EL AMANECER",
	1: "EL DESPERTAR",
	2: "LA EXPANSION",
	3: "LA ERA DE LOS HIJOS"
}

const ERA_DESCRIPTIONS = {
	0: "Antes del tiempo, antes de la luz, existia el Vacio Potencial. " +
	   "En ese Vacio, una chispa de consciencia primigenia contemplo su propia existencia " +
	   "y en ese acto de introspeccion, el universo nacio.",
	1: "Cuando el mundo se enfrio y las aguas se separaron de la tierra, " +
	   "la vida broto no por azar sino por necesidad. Como un parpado que se abre y se cierra, " +
	   "la existencia misma encontro su equilibrio en la pregunta ancestral: " +
	   "¿que fue primero, el huevo o la gallina? La respuesta se manifestaba en cada criatura.",
	2: "Veinticuatro hombres y veinticuatro mujeres de todas las razas, formas y tamanos, " +
	   "surgieron en el centro del mundo. No recordaban haber nacido ni haber sido creados. " +
	   "Simplemente abrieron los ojos y se encontraron bajo el sol. " +
	   "A su alrededor, animales, plantas y hongos se extendian por cada zona, " +
	   "cada cual con sus ciclos, sus necesidades, su danza vital. " +
	   "Los cuarenta y ocho se miraron unos a otros y supieron que estaban solos " +
	   "con su pensamiento. Y ese pensamiento era tanto un don como una carga.",
	3: "Los hijos de los cuarenta y ocho se expandieron por el mundo. " +
	   "Fundaron civilizaciones, alzaron muros, escribieron historias. " +
	   "Pero la conciencia que heredaron les susurraba preguntas sin respuesta: " +
	   "¿Quien soy? ¿Por que existo? ¿Que hay mas alla de lo que veo? " +
	   "Cada civilizacion respondio a su manera. Y en sus respuestas, " +
	   "forjaron su destino."
}

const CIV_LINAGES = {
	"enano": {
		"desc": "Hijos de la piedra y el metal, los enanos descienden de aquellos " +
				"de los cuarenta y ocho que miraron hacia abajo y encontraron " +
				"respuestas en las profundidades. Su conciencia esta ligada a la tierra " +
				"y encuentran paz en el martilleo ritual de la forja.",
		"traits": ["orgullosos", "laboriosos", "leales", "tozudos"],
		"need_prefix": "La piedra llama: ",
		"thought_bias": 0.2
	},
	"humano": {
		"desc": "Los mas diversos y adaptables. Descienden de aquellos que " +
				"miraron al horizonte y nunca dejaron de caminar. Su conciencia " +
				"es un fuego inquieto que los impulsa a construir, destruir y " +
				"reconstruir eternamente.",
		"traits": ["curiosos", "ambiciosos", "creativos", "impredecibles"],
		"need_prefix": "El horizonte espera: ",
		"thought_bias": 0.5
	},
	"elfo": {
		"desc": "Hijos del bosque y la memoria larga. Descienden de aquellos " +
				"que escucharon el susurro de las hojas y comprendieron que la " +
				"vida es un ciclo sin fin. Su conciencia se expande como las " +
				"ramas de un arbol milenario.",
		"traits": ["sabios", "pacientes", "orgullosos", "melancolicos"],
		"need_prefix": "El bosque recuerda: ",
		"thought_bias": 0.0
	},
	"orco": {
		"desc": "Forjados en la adversidad. Descienden de aquellos que " +
				"enfrentaron la oscuridad y decidieron que la fuerza era la " +
				"unica respuesta verdadera. Su conciencia es simple y directa, " +
				"como una llama que solo sabe arder.",
		"traits": ["feroces", "honorables", "resistentes", "impulsivos"],
		"need_prefix": "La sangre exige: ",
		"thought_bias": -0.2
	},
	"trasgo": {
		"desc": "Nacidos de las sombras y la astucia. Descienden de aquellos " +
				"que aprendieron que la realidad es maleable y que la verdad " +
				"es solo una herramienta mas. Su conciencia retuerce el mundo " +
				"para adaptarlo a sus suenos.",
		"traits": ["astutos", "inventivos", "traviesos", "desconfiados"],
		"need_prefix": "La sombra susurra: ",
		"thought_bias": -0.1
	}
}

const BESTIARY = {
	"Fox": {
		"lore": "El zorro fue el primer animal en aprender a observar. " +
				"Se dice que los cuarenta y ocho vieron su mirada y supieron " +
				"que no estaban solos en su consciencia.",
		"significado": "astucia, observacion, adaptabilidad"
	},
	"Rabbit": {
		"lore": "Los conejos representan el ciclo eterno de vida y muerte. " +
				"Su fertilidad es un recordatorio de que la existencia siempre " +
				"encuentra un camino.",
		"significado": "fertilidad, supervivencia, ciclo"
	},
	"Squirrel": {
		"lore": "La ardilla guarda secretos en los arboles. Los sabios dicen " +
				"que si observas a una ardilla el tiempo suficiente, " +
				"aprenderas el valor de la previsión.",
		"significado": "prevision, laboriosidad, paciencia"
	},
	"Deer": {
		"lore": "El ciervo es mensajero entre los mundos. Su cornamenta " +
				"alcanza el cielo mientras sus pezuñas tocan la tierra, " +
				"uniendo lo divino con lo terrenal.",
		"significado": "nobleza, conexion, equilibrio"
	},
	"Boar": {
		"lore": "El jabali enseno a los cuarenta y ocho que la ferocidad " +
				"bien dirigida es proteccion, no violencia. Sus colmillos " +
				"son la memoria de la tierra.",
		"significado": "ferocidad, proteccion, determinacion"
	},
	"Wolf": {
		"lore": "El lobo fue el primer maestro de la humanidad. Les enseno " +
				"a cazar en manada, a respetar la jerarquia y a aullar a la " +
				"luna en busca de respuestas.",
		"significado": "lealtad, manada, libertad"
	},
	"Bear": {
		"lore": "El oso es la fuerza primordial. Cuando los cuarenta y ocho " +
				"dudaron, el oso les mostro que la verdadera fuerza esta en " +
				"la paciencia y el descanso antes de la accion.",
		"significado": "fuerza, introspeccion, proteccion"
	},
	"Lion": {
		"lore": "El leon fue coronado rey no por su fuerza, sino porque " +
				"fue el unico que miro al sol sin parpadear. Su rugido " +
				"contiene el eco del primer amanecer.",
		"significado": "realeza, valor, orgullo"
	},
	"Elephant": {
		"lore": "Los elefantes caminan sobre la memoria del mundo. " +
				"Se dice que nunca olvidan porque ellos presenciaron el " +
				"nacimiento de los cuarenta y ocho.",
		"significado": "memoria, sabiduria, longevidad"
	},
	"Tiger": {
		"lore": "El tigre es el cazador perfecto, la paciencia hecha carne. " +
				"Representa el momento entre la decision y la accion, " +
				"el instante en que todo cambia.",
		"significado": "paciencia, sigilo, perfeccion"
	},
	"Dragon": {
		"lore": "Los dragones son fragmentos del Vacio Potencial original " +
				"que tomaron forma. No nacieron como las demas criaturas, " +
				"sino que se manifestaron cuando el mundo necesito recordar " +
				"su origen caotico.",
		"significado": "caos primigenio, poder, trascendencia"
	}
}

var world_seed: int
var world_name: String
var creation_date: Dictionary = {}
var civ_lores: Array = []
var era_events: Dictionary = {}

func _init(seed_val: int, w_name: String):
	world_seed = seed_val
	world_name = w_name
	_generate_creation_date()

func _generate_creation_date() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed

	var part1 = rng.randi_range(1000000, 9999999)
	var part2 = rng.randi_range(100, 999)
	creation_date = {
		"era0_start": part1,
		"era1_start": part1 + rng.randi_range(10000, 50000),
		"era2_start": part1 + rng.randi_range(50000, 200000),
		"era3_start": part1 + rng.randi_range(200000, 500000),
		"current_year": part1 + 500000 + 63
	}

func get_creation_myth() -> String:
	var myth = ""
	myth += "== LA CREACION DE %s ==\n\n" % world_name
	myth += "En el principio, no habia nada. Y ese nada era todo lo que existia.\n"
	myth += "Pero en el corazon del Vacio, una pregunta na cio sin voz:\n"
	myth += "   ¿Que soy?\n\n"
	myth += "Y al hacerse esa pregunta, el Vacio dejo de ser vacio.\n"
	myth += "El Big Bang no fue una explosion: fue la respuesta a esa pregunta.\n"
	myth += "El universo se desplego como un parpado que se abre,\n"
	myth += "y al cerrarse, dejo ver lo que habia estado siempre alli.\n\n"
	myth += "== EL AGUA DE LA LUNA ==\n\n"
	myth += "Cuando la Tierra era joven y ardiente, un fragmento de la Luna\n"
	myth += "cayo del cielo. No fue un accidente ni un castigo.\n"
	myth += "Fue el equilibrio: el fuego necesitaba agua, y la luna,\n"
	myth += "que siempre habia mirado a la tierra con anhelo,\n"
	myth += "entrego un pedazo de si misma para que la vida pudiera comenzar.\n\n"
	myth += "El fragmento lunar se fundio en los oceanos, y en ese abrazo\n"
	myth += "de fuego y agua, nacio el caldo primordial.\n\n"
	myth += "== EL HUEVO Y LA GALLINA ==\n\n"
	myth += "La vida no surgio por casualidad. Surgio porque la existencia misma\n"
	myth += "buscaba completarse. Es como abrir y cerrar los ojos:\n"
	myth += "no hay un antes ni un despues, solo el acto de percibir.\n"
	myth += "¿Que fue primero, el huevo o la gallina?\n"
	myth += "Ambos, y ninguno. Porque la vida no es una cadena de causas,\n"
	myth += "sino un circulo que se cierra sobre si mismo.\n"
	myth += "El primer organismo fue huevo y gallina simultaneamente,\n"
	myth += "auto-contenido, auto-consciente, completo.\n\n"
	myth += "== LOS CUARENTA Y OCHO ==\n\n"
	myth += "Pasaron eones. Las especies nacieron y murieron.\n"
	myth += "Los continentes danzaron sobre el magma.\n"
	myth += "Y entonces, un dia como cualquier otro,\n"
	myth += "veinticuatro hombres y veinticuatro mujeres abrieron los ojos.\n\n"
	myth += "No habia un lugar sagrado ni un momento especial.\n"
	myth += "Simplemente estaban alli, en el centro del mundo,\n"
	myth += "rodeados de animales, plantas y hongos.\n"
	myth += "Cada uno era diferente: altos, bajos, oscuros, claros,\n"
	myth += "de todas las formas y tamanos que la humanidad podia tomar.\n\n"
	myth += "Y en el instante en que se miraron unos a otros,\n"
	myth += "supieron lo que los animales no sabrian jamas:\n"
	myth += "que existian, que eran conscientes, que estaban solos\n"
	myth += "con sus pensamientos.\n\n"
	myth += "Esa conciencia fue su don y su condena.\n"
	myth += "Porque pensar no es solo mirar el mundo:\n"
	myth += "es preguntarse por que lo miras.\n"
	myth += "Y esa pregunta no tiene respuesta.\n\n"
	myth += "== LA EXPANSION ==\n\n"
	myth += "Los cuarenta y ocho se separaron. Algunos miraron hacia abajo\n"
	myth += "y encontraron refugio en la piedra: fueron los enanos.\n"
	myth += "Otros miraron al horizonte y caminaron: fueron los humanos.\n"
	myth += "Otros escucharon el viento en los arboles: fueron los elfos.\n"
	myth += "Y otros abrazaron la oscuridad y la fuerza: fueron los orcos\n"
	myth += "y los trasgos.\n\n"
	myth += "Cada civilizacion heredo la conciencia de los cuarenta y ocho,\n"
	myth += "pero cada una encontro su propia manera de soportarla.\n"
	myth += "Construyeron murallas para contener el vacio.\n"
	myth += "Escribieron historias para dar sentido al tiempo.\n"
	myth += "Hicieron la guerra para sentirse vivos.\n"
	myth += "Y siempre, siempre, se preguntaron:\n"
	myth += "    ¿Que soy?\n\n"
	myth += "Pasaron 63 anos desde que los primeros reinos se alzaron.\n"
	myth += "El mundo de %s respira, sufre, suena.\n" % world_name
	myth += "Y en alguna parte, un parpado se abre...\n"
	myth += "y la pregunta sigue esperando respuesta."
	return myth

func get_era_summary(era: int) -> String:
	if ERAS.has(era):
		return "%s: %s" % [ERAS[era], ERA_DESCRIPTIONS[era]]
	return ""

func get_civ_lore(civ_type: String) -> Dictionary:
	return CIV_LINAGES.get(civ_type, CIV_LINAGES["humano"])

func get_bestiary_lore(creature_name: String) -> Dictionary:
	return BESTIARY.get(creature_name, {"lore": "No hay registro de esta criatura.", "significado": "desconocido"})

func get_philosophical_question() -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed + Time.get_ticks_msec()
	var questions = [
		"¿Que fue primero, el huevo o la gallina?",
		"¿Si un arbol cae en el bosque y nadie lo oye, hace ruido?",
		"¿Que soy?",
		"¿Por que hay algo en lugar de nada?",
		"¿El tiempo fluye o somos nosotros los que fluimos?",
		"¿Puede la conciencia comprenderse a si misma?",
		"¿El destino existe o todo es casualidad?",
		"¿Que separa al sueno de la realidad?",
		"¿Si todo muere, que sentido tiene vivir?",
		"¿El amor es quimica o eleccion?"
	]
	return questions[rng.randi() % questions.size()]

func get_inspirational_thought() -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed + Time.get_ticks_msec() / 1000
	var thoughts = [
		"El martillo cae y la piedra cede. En cada golpe, una pregunta encuentra su respuesta.",
		"El camino se hace al andar. Pero alguien debe dar el primer paso.",
		"La montana no se mueve, pero el minero si. ¿Quien es mas fuerte?",
		"Un muro no solo separa: tambien protege. ¿Que proteges tu?",
		"El metal se calienta, se golpea, se enfría. ¿Cuantas veces has renacido?",
		"El agua busca su nivel. La consciencia busca su proposito.",
		"No hay sueno sin vigilia. No hay muerte sin vida. No hay yo sin tu.",
		"La tierra recuerda. La piedra guarda silencio. Pero el minero escucha.",
		"Los dedos del herrero recuerdan lo que la mente olvida.",
		"Una fortaleza no son sus muros: son las historias que alberga."
	]
	return thoughts[rng.randi() % thoughts.size()]

func get_world_name_meaning() -> String:
	var syllables = []
	var name_lower = world_name.to_lower()
	for i in range(0, name_lower.length(), 2):
		var end = min(i + 2, name_lower.length())
		syllables.append(name_lower.substr(i, end - i))
	
	var meanings = {
		"ara": "El Amanecer",
		"bel": "La Fortaleza",
		"cal": "El Abismo",
		"dor": "Puerta",
		"ere": "El Sueño",
		"fal": "El Martillo",
		"gar": "La Lanza",
		"hal": "El Susurro",
		"ith": "La Pregunta",
		"kel": "El Canto",
		"lor": "El Bosque",
		"mor": "La Sombra",
		"nor": "El Monte",
		"oth": "El Juramento",
		"pel": "El Muro",
		"ral": "El Rio",
		"sil": "La Luna",
		"tal": "La Raiz",
		"ur": "El Primero",
		"val": "El Poder",
		"yor": "El Anillo",
		"zol": "La Chispa",
		"mar": "El Mar",
		"vir": "El Cristal",
		"dal": "El Valle",
		"bar": "La Forja",
		"thar": "El Trueno",
		"mir": "La Mirada",
		"nis": "El Crepusculo",
		"dur": "Eterno",
		"caed": "Caida",
		"jard": "Jardin",
		"hon": "Honduras",
		"kar": "Rey",
		"lon": "Largo",
		"nan": "Pequeño",
		"rion": "Reino",
		"sia": "Sabiduria",
		"tar": "Torre",
		"van": "Esperanza",
		"wyr": "Dragón",
		"zar": "Secreto",
		"thal": "Fuerza",
		"lund": "Tierra",
		"morn": "Mañana",
		"rath": "Rueda",
		"stead": "Lugar",
		"wick": "Mecha",
		"deep": "Profundo",
		"peak": "Cima",
		"vale": "Valle",
		"heim": "Hogar",
		"mark": "Marca",
		"gard": "Guardia",
		"hold": "Refugio",
		"glor": "Gloria",
		"rim": "Borde",
		"bron": "Peña",
		"dol": "Colina"
	}
	
	var meaning_parts = []
	for s in syllables:
		if meanings.has(s):
			meaning_parts.append(meanings[s])
	
	if meaning_parts.is_empty():
		return "El nombre de %s es un misterio, como el origen de la consciencia misma." % world_name
	
	var meaning_str = " se traduce como "
	if meaning_parts.size() == 1:
		meaning_str += meaning_parts[0]
	elif meaning_parts.size() == 2:
		meaning_str += meaning_parts[0] + " de " + meaning_parts[1]
	else:
		meaning_str += meaning_parts[0]
		for i_371 in range(1, meaning_parts.size()):
			if i_371 == meaning_parts.size() - 1:
				meaning_str += " y " + meaning_parts[i_371]
			else:
				meaning_str += ", " + meaning_parts[i_371]
	
	return meaning_str

# ===========================================================================================
# MODO LEYENDAS - Figuras Históricas, Artefactos, Sitios
# ===========================================================================================
func get_artifact_lore(art_name: String, art_type: String, art_material: String, creator: String, year: int) -> String:
	var text = "=== La Reliquia: %s ===\n" % art_name
	text += "Tipo: %s | Material: %s\n" % [art_type, art_material]
	text += "Forjado por: %s en el año %d\n\n" % [creator, year]
	text += _generate_artifact_legend(art_name, art_type, art_material, creator)
	return text

func _generate_artifact_legend(art_name: String, art_type: String, material: String, creator: String) -> String:
	var intros = [
		"Se cuenta que %s entró en un estado de fervorosa obsesión,",
		"En un trance que duró tres días con sus noches, %s",
		"Las crónicas registran que %s murmuró palabras en lengua antigua mientras",
		"Testigos presenciaron cómo %s rechazó comer y dormir hasta que",
	]
	var mids = [
		"reunió %s de los almacenes más profundos de la fortaleza." % material,
		"demandó %s con ojos de locura sagrada." % material,
		"tomó el último stock de %s disponible sin pedir permiso." % material,
	]
	var endings = [
		"El resultado fue %s, una obra de arte que trasciende el tiempo." % art_name,
		"Nadie sabe cómo logró tal maravilla. %s es su legado eterno." % art_name,
		"%s fue presentado ante la fortaleza en silencio absoluto. Todos sintieron su poder." % art_name,
	]
	var rng = RandomNumberGenerator.new()
	rng.seed = art_name.hash()
	return (intros[rng.randi() % intros.size()] % creator) + " " + mids[rng.randi() % mids.size()] + "\n" + endings[rng.randi() % endings.size()]

func get_legendary_beast_lore(beast_name: String) -> String:
	var text = "=== La Bestia Legendaria: %s ===\n" % beast_name
	var origins = [
		"Emergió del magma subterráneo durante la segunda era.",
		"Fue creada cuando la magia desbordó los límites del mundo conocido.",
		"Es un remanente viviente de la edad del caos primigenio.",
		"Nació del miedo colectivo de mil generaciones de aldeanos.",
	]
	var traits = [
		"Su aliento corroe el acero más puro.",
		"Sus ojos pueden ver en la oscuridad absoluta.",
		"Se dice que puede leer los pensamientos de sus presas.",
		"Ningún arma forjada por manos no legendarias puede herirla.",
		"Lleva siglos durmiendo bajo la tierra, esperando ser despertada.",
	]
	var rng = RandomNumberGenerator.new()
	rng.seed = beast_name.hash()
	text += origins[rng.randi() % origins.size()] + "\n"
	text += traits[rng.randi() % traits.size()] + "\n"
	text += traits[rng.randi() % traits.size()] + "\n"
	text += "\nMatar a esta criatura sería una de las mayores hazañas registradas en la historia del mundo."
	return text

func get_civilization_extended_lore(civ_name: String, race: String, pop: int, sites_count: int) -> String:
	var text = "=== Civilización: %s ===\n" % civ_name
	text += "Raza: %s | Población total estimada: %d | Asentamientos: %d\n\n" % [_get_race_display(race), pop, sites_count]
	var civ_data = CIV_LINAGES.get(race, CIV_LINAGES.get("humano", {}))
	if not civ_data.is_empty():
		text += civ_data.get("desc", "") + "\n\n"
		text += "Rasgos característicos: %s\n" % ", ".join(civ_data.get("traits", []))
	return text

func _get_race_display(race: String) -> String:
	match race:
		"dwarf":  return "Enanos"
		"elf":    return "Elfos"
		"goblin": return "Goblins"
		"human":  return "Humanos"
	return race.capitalize()

func get_invasion_lore(inv_type_name: String, enemy: String) -> String:
	var lore_map = {
		"Goblin":   "Los goblins son criaturas de inteligencia media que viven para el saqueo y la guerra. Organizan incursiones contra fortalezas ricas buscando metal, comida y esclavos.",
		"Zombie":   "Los muertos vivientes no sienten dolor, miedo ni fatiga. Solo obedecen la voluntad del nigromante que los controla. Su única debilidad es la separación física.",
		"Kobold":   "Los kobolds son cleptómanos compulsivos. Rara vez atacan de frente; prefieren robar de los almacenes durante la noche. Eliminad a los centinelas primero.",
		"Skeleton": "Huesos animados por magia oscura. No pueden ser heridos por sangrado. Solo el daño contundente o la magia sagrada los destruye permanentemente.",
		"Elf":      "Los elfos que llegan con armas desenvainadas han agotado su paciencia diplomática. Son arqueros mortales y guerreros ágiles. Sus demandas sobre los árboles deben tomarse en serio.",
	}
	var key = enemy.split(" ")[0]
	return lore_map.get(key, "Poco se sabe de esta amenaza. Preparad las defensas y esperad.")
