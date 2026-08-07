extends Area3D

var rnd = RandomNumberGenerator.new()

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

#func _on_area_entered(other_area: Area3D) -> void:
#	# Prüfen, ob das andere Objekt gültig ist und zur Gruppe gehört
#	if is_instance_valid(other_area) and other_area.is_in_group("Ground3D"):
#		
#		# Deterministische Regel: Nur der Node mit der HÖHEREN Instanz-ID löscht SICH SELBST.
#		# Der Node mit der niedrigeren ID bleibt stehen. Dadurch wird kein Node doppelt gefreed!
#		if get_instance_id() > other_area.get_instance_id():
#			# Kurzer zufälliger Offset, falls nötig, aber Sicherheitscheck vor queue_free
#			await wait(rnd.randf_range(0.01, 0.1))
#			
#			if is_instance_valid(self) and not is_queued_for_deletion():
#				queue_free()


#func _on_body_entered(body: Node3D) -> void:
#		# Prüfen, ob das andere Objekt gültig ist und zur Gruppe gehört
#	if is_instance_valid(body) and body.is_in_group("Ground3D"):
#		
#		# Deterministische Regel: Nur der Node mit der HÖHEREN Instanz-ID löscht SICH SELBST.
#		# Der Node mit der niedrigeren ID bleibt stehen. Dadurch wird kein Node doppelt gefreed!
#		if get_instance_id() > body.get_instance_id():
#			# Kurzer zufälliger Offset, falls nötig, aber Sicherheitscheck vor queue_free
#			await wait(rnd.randf_range(0.01, 0.1))
#			
#			if is_instance_valid(self) and not is_queued_for_deletion():
#				queue_free()
