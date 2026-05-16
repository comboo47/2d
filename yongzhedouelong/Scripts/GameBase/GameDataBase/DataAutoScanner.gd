# BuffAutoScanner.gd
extends Node

# 在项目设置中设置为autoload，在BuffRegistry之后加载

@export var scan_directories: Array[String] = [
	"res://prefab/Buffs/"
]

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# 延迟扫描，确保所有资源已加载
	call_deferred("scan_and_register")

func scan_and_register() -> void:
	print("开始扫描Buff资源...")
	var count = 0
	
	for dir_path in scan_directories:
		var dir = DirAccess.open(dir_path)
		if not dir:
			push_warning("无法打开目录: %s" % dir_path)
			continue
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var full_path = dir_path.path_join(file_name)
				var resource:AttributeBuff = load(full_path)
				if resource and resource is AttributeBuff:
					# 确保资源已经加载了其属性（应该已经加载，因为使用了load函数）
					if resource.get_runtime_id().is_empty():
						push_warning("Buff资源缺少ID，跳过: %s" % full_path)
					else:
						DataRegistry.instance.register_buff(resource)
						count += 1
			file_name = dir.get_next()
	
	print("Buff扫描完成，找到 %d 个Buff资源" % count)
