# InventoryUI.gd - Simple inventory interface
class_name InventoryUI
extends Control

var inventory: Inventory
var item_buttons: Array[Button] = []
var info_label: RichTextLabel
var equipped_labels: Dictionary = {}

signal item_used(item: Item)
signal close_inventory

func _ready():
	visible = false
	create_ui()

func create_ui():
	# Main panel
	var panel = Panel.new()
	panel.size = Vector2(400, 300)
	panel.position = Vector2(50, 50)
	add_child(panel)
	
	# Title
	var title = Label.new()
	title.text = "Inventory"
	title.position = Vector2(10, 10)
	panel.add_child(title)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.size = Vector2(30, 30)
	close_btn.position = Vector2(360, 10)
	close_btn.pressed.connect(hide_inventory)
	panel.add_child(close_btn)
	
	# Equipment labels
	var equip_label = Label.new()
	equip_label.text = "Equipment:"
	equip_label.position = Vector2(10, 40)
	panel.add_child(equip_label)
	
	equipped_labels["weapon"] = Label.new()
	equipped_labels["weapon"].text = "Weapon: None"
	equipped_labels["weapon"].position = Vector2(10, 60)
	panel.add_child(equipped_labels["weapon"])
	
	equipped_labels["armor"] = Label.new()
	equipped_labels["armor"].text = "Armor: None"
	equipped_labels["armor"].position = Vector2(10, 80)
	panel.add_child(equipped_labels["armor"])
	
	# Inventory grid
	var grid = GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(10, 110)
	grid.size = Vector2(250, 150)
	panel.add_child(grid)
	
	# Create item buttons
	for i in range(20):
		var button = Button.new()
		button.custom_minimum_size = Vector2(48, 48)
		button.text = ""
		button.pressed.connect(_on_item_button_pressed.bind(i))
		grid.add_child(button)
		item_buttons.append(button)
	
	# Info panel
	info_label = RichTextLabel.new()
	info_label.position = Vector2(270, 110)
	info_label.size = Vector2(120, 150)
	info_label.bbcode_enabled = true
	info_label.text = "Select an item to see details."
	panel.add_child(info_label)

func setup_inventory(inv: Inventory):
	inventory = inv
	inventory.inventory_changed.connect(refresh_display)
	inventory.item_equipped.connect(_on_item_equipped)
	inventory.item_unequipped.connect(_on_item_unequipped)
	refresh_display()

func refresh_display():
	if not inventory:
		return
	
	# Clear all buttons
	for button in item_buttons:
		button.text = ""
		button.disabled = false
	
	# Update with current items
	var stacks = inventory.get_all_items()
	for i in range(min(stacks.size(), item_buttons.size())):
		var stack = stacks[i]
		var button = item_buttons[i]
		button.text = stack.item.item_name
		if stack.quantity > 1:
			button.text += "\n(" + str(stack.quantity) + ")"
		
		# Color based on item type
		button.modulate = stack.item.get_rarity_color()

func _on_item_button_pressed(index: int):
	if not inventory:
		return
	
	var stacks = inventory.get_all_items()
	if index >= stacks.size():
		return
	
	var stack = stacks[index]
	show_item_info(stack.item)
	
	# Use/equip item on double-click (simplified to single click for now)
	if stack.item.usable:
		inventory.use_item(stack.item)
		item_used.emit(stack.item)

func show_item_info(item: Item):
	if info_label:
		info_label.text = item.get_tooltip_text()

func _on_item_equipped(item: Item):
	match item.item_type:
		"weapon":
			equipped_labels["weapon"].text = "Weapon: " + item.item_name
		"armor":
			equipped_labels["armor"].text = "Armor: " + item.item_name

func _on_item_unequipped(item: Item):
	match item.item_type:
		"weapon":
			equipped_labels["weapon"].text = "Weapon: None"
		"armor":
			equipped_labels["armor"].text = "Armor: None"

func show_inventory():
	visible = true

func hide_inventory():
	visible = false
	close_inventory.emit()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		hide_inventory()
