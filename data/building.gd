@tool
class_name Building
extends Resource
## Модель данных жилища.


## Характеристики жилища.
enum Stat {
	STRENGTH, ## Прочность.
	COMFORT,  ## Комфорт.
	CAPACITY, ## Вместительность.
}

## Тип ресурса.
enum ResourceType {
	A,    ## Ресурс A.
	B,    ## Ресурс B.
	C,    ## Ресурс C.
	FOOD, ## Еда.
	AMMO, ## Боеприпасы.
}

## Минимальный уровень характеристики.
const STAT_MIN_LEVEL: int = 1

## Максимальный уровень характеристики.
const STAT_MAX_LEVEL: int = 11

const _STATS_PREFIX: String = "stats/"
const _STORAGE_PREFIX: String = "storage/"

var _stat_levels: Array[int]
var _storage_size: int
var _resources: Array[int]


## Возвращает название характеристики [param stat].
static func get_stat_name(stat: Stat) -> String:
	match stat:
		Stat.STRENGTH: return "Прочность"
		Stat.COMFORT:  return "Комфорт"
		Stat.CAPACITY: return "Вместительность"
	breakpoint
	return ""


## Возвращает название параметра [param param_id].
static func get_stat_param_name(param_id: String) -> String:
	match param_id:
		"wall_protection":     return "Защита стены"
		"building_protection": return "Защита жилища"
		"fighters_attack":     return "Атака бойцов"
		"construction_attack": return "Атака сооружений"
		"storage_size":        return "Мест на складе"
		"construction_count":  return "Доступно сооружений"
	breakpoint
	return ""


## Возвращает стоимость повышения уровня характеристики [param stat]
## с [code]level - 1[/code] на 1 (до [param level]).
static func get_upgrade_cost(stat: Stat, level: int) -> Dictionary:
	assert(STAT_MIN_LEVEL < level and level <= STAT_MAX_LEVEL)
	var result: Dictionary = {}
	var lv: int = level - STAT_MIN_LEVEL
	match stat:
		Stat.STRENGTH:
			result[ResourceType.A] = 2 * lv
		Stat.COMFORT:
			result[ResourceType.A] = 4 + 2 * lv
			result[ResourceType.B] = 3 * lv
			result[ResourceType.C] = 2 * lv
		Stat.CAPACITY:
			result[ResourceType.A] = 3 * lv
			result[ResourceType.C] = lv
		_:
			breakpoint
	return result


## Возвращает иконку ресурса [param res_type].
static func get_resource_icon(res_type: ResourceType) -> Texture2D:
	var id: String = ResourceType.find_key(res_type).to_lower()
	return load("res://assets/icons/resource_%s.png" % id)


## Возвращает название ресурса [param res_type].
static func get_resource_name(res_type: ResourceType) -> String:
	match res_type:
		ResourceType.A:    return "Ресурс A"
		ResourceType.B:    return "Ресурс B"
		ResourceType.C:    return "Ресурс C"
		ResourceType.FOOD: return "Еда"
		ResourceType.AMMO: return "Боеприпасы"
	breakpoint
	return ""


## Возвращает параметры характеристики [param stat] для уровня [param level]
## в виде словаря [code]String -> int[/code]. Ключами являются ID параметров.
static func get_stat_params(stat: Stat, level: int) -> Dictionary:
	assert(STAT_MIN_LEVEL <= level and level <= STAT_MAX_LEVEL)
	var result: Dictionary = {}
	var lv: int = level - STAT_MIN_LEVEL
	match stat:
		Stat.STRENGTH:
			result.wall_protection = 10 + lv
			result.building_protection = 10 + lv
		Stat.COMFORT:
			result.fighters_attack = 1 + lv
			result.construction_attack = 1 + lv
		Stat.CAPACITY:
			result.storage_size = 50 + 5 * lv
			result.construction_count = 7 + lv
		_:
			breakpoint
	return result


func _init() -> void:
	_stat_levels.resize(Stat.size())
	_stat_levels.fill(STAT_MIN_LEVEL)

	@warning_ignore("static_called_on_instance")
	_storage_size = get_stat_params(Stat.CAPACITY, STAT_MIN_LEVEL).storage_size

	_resources.resize(ResourceType.size())
	_resources.fill(0)


func _get_property_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stat in Stat:
		result.append({
			name = _STATS_PREFIX + stat.to_lower(),
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "%d,%d" % [STAT_MIN_LEVEL, STAT_MAX_LEVEL],
		})
	for res_type in ResourceType:
		result.append({
			name = _STORAGE_PREFIX + res_type.to_lower(),
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0,%d" % _storage_size,
		})
	return result


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with(_STATS_PREFIX):
		var key: String = property.trim_prefix(_STATS_PREFIX).to_upper()
		set_stat_level(Stat[key], value)
		return true
	if property.begins_with(_STORAGE_PREFIX):
		var key: String = property.trim_prefix(_STORAGE_PREFIX).to_upper()
		set_resource_amount(ResourceType[key], value)
		return true
	return false


func _get(property: StringName) -> Variant:
	if property.begins_with(_STATS_PREFIX):
		var key: String = property.trim_prefix(_STATS_PREFIX).to_upper()
		return get_stat_level(Stat[key])
	if property.begins_with(_STORAGE_PREFIX):
		var key: String = property.trim_prefix(_STORAGE_PREFIX).to_upper()
		return get_resource_amount(ResourceType[key])
	return null


func _property_can_revert(property: StringName) -> bool:
	if property.begins_with(_STATS_PREFIX):
		return true
	if property.begins_with(_STORAGE_PREFIX):
		return true
	return false


func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with(_STATS_PREFIX):
		return STAT_MIN_LEVEL
	if property.begins_with(_STORAGE_PREFIX):
		return 0
	return null


## Задаёт уровень характеристики [param stat].
func set_stat_level(stat: Stat, level: int) -> void:
	assert(STAT_MIN_LEVEL <= level and level <= STAT_MAX_LEVEL)
	_stat_levels[stat] = level
	if stat == Stat.CAPACITY:
		@warning_ignore("static_called_on_instance")
		_storage_size = get_stat_params(stat, level).storage_size
		for res_type in ResourceType.size():
			_resources[res_type] = mini(_resources[res_type], _storage_size)
		notify_property_list_changed()
	emit_changed()


## Возвращает уровень характеристики параметра [param stat].
func get_stat_level(stat: Stat) -> int:
	return _stat_levels[stat]


## Возвращает максимальное количество ресурса на складе.
func get_storage_size() -> int:
	return _storage_size


## Задаёт количество ресурса [param res_type] на складе.
func set_resource_amount(res_type: ResourceType, amount: int) -> void:
	assert(0 <= amount and amount <= _storage_size)
	_resources[res_type] = amount
	emit_changed()


## Возвращает количество ресурса [param res_type] на складе.
func get_resource_amount(res_type: ResourceType) -> int:
	return _resources[res_type]


## Возвращает, возможно ли повысить уровень характеристики [param stat].
func can_upgrade(stat: Stat) -> bool:
	var new_level: int = get_stat_level(stat) + 1
	if new_level > STAT_MAX_LEVEL:
		return false

	@warning_ignore("static_called_on_instance")
	var cost: Dictionary = get_upgrade_cost(stat, new_level)
	for res_type in cost:
		if get_resource_amount(res_type) < cost[res_type]:
			return false

	return true


## Повышает уровень характеристики [param stat], расходуя ресурсы со склада.
func upgrade(stat: Stat) -> void:
	assert(can_upgrade(stat))

	var new_level: int = get_stat_level(stat) + 1

	@warning_ignore("static_called_on_instance")
	var cost: Dictionary = get_upgrade_cost(stat, new_level)
	for res_type in cost:
		set_resource_amount(res_type, get_resource_amount(res_type) - cost[res_type])

	set_stat_level(stat, new_level)
