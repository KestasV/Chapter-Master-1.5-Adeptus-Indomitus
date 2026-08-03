/// @DnDAction : YoYo Games.Common.Execute_Code
/// @DnDVersion : 1
/// @DnDHash : 23A4C597
/// @DnDArgument : "code" "/// @description Input, camera, and the simulation clock.$(13_10)$(13_10)var _mgx = device_mouse_x_to_gui(0);$(13_10)var _mgy = device_mouse_y_to_gui(0);$(13_10)var _lc = mouse_check_button_pressed(mb_left);$(13_10)var _rc = mouse_check_button_pressed(mb_right);$(13_10)var _lheld = mouse_check_button(mb_left);$(13_10)var _lrel = mouse_check_button_released(mb_left);$(13_10)var _rheld = mouse_check_button(mb_right);$(13_10)var _rrel = mouse_check_button_released(mb_right);$(13_10)$(13_10)if (!boot_done) {$(13_10)    boot_done = true;$(13_10)    instance_deactivate_all(true);$(13_10)    // instance_exists cannot see deactivated instances, so a guard here would$(13_10)    // always fail and leave the cursor frozen. Unconditional activation is a$(13_10)    // safe no-op if no cursor instance is around.$(13_10)    instance_activate_object(obj_cursor);$(13_10)	instance_activate_object(obj_ncombat);$(13_10)$(13_10)    grid_setup_field(id, pending_width);$(13_10)    grid_gen_structures(id);$(13_10)    grid_gen_cover(id);$(13_10)    // A bigger fight keeps coming for longer, so the wave count follows threat$(13_10)    // rather than sitting at the prototype's flat one.$(13_10)    waves_left = clamp(round(clamp(pending_threat, 1, 7) / 2), 1, 4);$(13_10)    if (array_length(pending_force) > 0) {$(13_10)        grid_import_force(id, pending_force);$(13_10)    } else {$(13_10)        grid_gen_player_pool(id);$(13_10)    }$(13_10)    grid_spawn_enemy_force(id);$(13_10)    grid_centre_view(id, GRIDC_DEPLOY_COLS, floor(rows / 2));$(13_10)    if (pending_loc != "") {$(13_10)        grid_log(id, $"Battle for {pending_loc}.", eMSG_COLOR.BRIGHT_BLUE);$(13_10)    }$(13_10)    grid_log(id, $"Deployment: up to {GRIDC_PLAYER_DEPLOY_CAP} squads, six lines deep, laid out by your formation settings.", eMSG_COLOR.BRIGHT_BLUE);$(13_10)    if (pending_live) {$(13_10)        grid_log(id, "Live battle: these are your real companies and your losses are permanent.", eMSG_COLOR.YELLOW);$(13_10)    }$(13_10)    grid_log(id, "Left click selects, drag a box to select several, right click orders.", eMSG_COLOR.AQUA);$(13_10)    grid_log(id, "Deploying: drag out the front rank and the block forms along it.", eMSG_COLOR.AQUA);$(13_10)    grid_log(id, "Ctrl and a number binds a control group, the number recalls it.", eMSG_COLOR.AQUA);$(13_10)    grid_log(id, "Right click drag places the selection in a shape. R sets ranks, X breaks a block up.", eMSG_COLOR.AQUA);$(13_10)    grid_log(id, "Chapter orders: F1 hold, F2 fire line, F3 advance, F4 advance and hold, F5 assault, F6 fall back.", eMSG_COLOR.AQUA);$(13_10)    grid_log(id, "WASD pans the field. Tab toggles the overview.", eMSG_COLOR.AQUA);$(13_10)}$(13_10)$(13_10)if (exit_arm > 0) {$(13_10)    exit_arm -= 1;$(13_10)}$(13_10)$(13_10)// Scrollback over the log strip, same wheel and scrollbar handling as a vanilla$(13_10)// battle. Scoped to the strip, so it never competes with the deployment popup's$(13_10)// own wheel scrolling.$(13_10)log.update_scroll(GRIDC_BF_X1 + 4, GRIDC_LOG_Y1, GRIDC_BF_X2 - GRIDC_BF_X1, GRIDC_LOG_Y2 - GRIDC_LOG_Y1);$(13_10)$(13_10)// ---------------------------------------------------------------------------$(13_10)// Camera and view keys. These run before the deployment popup and the placing$(13_10)// handler, both of which exit the event early. Sitting after them meant the$(13_10)// camera was frozen for the whole of deployment: you could not look at the$(13_10)// ground you were being asked to deploy onto. Nothing here touches game state,$(13_10)// so it is safe at the top.$(13_10)// ---------------------------------------------------------------------------$(13_10)// ---------------------------------------------------------------------------$(13_10)// Camera and hotkeys.$(13_10)// ---------------------------------------------------------------------------$(13_10)if (keyboard_check(ord("A")) || keyboard_check(vk_left)) {$(13_10)    view_x -= GRIDC_SCROLL_SPEED;$(13_10)}$(13_10)if (keyboard_check(ord("D")) || keyboard_check(vk_right)) {$(13_10)    view_x += GRIDC_SCROLL_SPEED;$(13_10)}$(13_10)if (keyboard_check(ord("W")) || keyboard_check(vk_up)) {$(13_10)    view_y -= GRIDC_SCROLL_SPEED;$(13_10)}$(13_10)if (keyboard_check(ord("S")) || keyboard_check(vk_down)) {$(13_10)    view_y += GRIDC_SCROLL_SPEED;$(13_10)}$(13_10)grid_clamp_view(id);$(13_10)$(13_10)if (keyboard_check_pressed(vk_tab)) {$(13_10)    var _tc = (hover_c >= 0) ? hover_c : floor(cols / 2);$(13_10)    var _tr = (hover_r >= 0) ? hover_r : floor(rows / 2);$(13_10)    zoom_mode = (zoom_mode == 0) ? 1 : 0;$(13_10)    grid_centre_view(id, _tc, _tr);$(13_10)}$(13_10)$(13_10)// Minus and plus step the clock, on both the main row and the numpad.$(13_10)if (keyboard_check_pressed(vk_subtract) || keyboard_check_pressed(189)$(13_10)    || keyboard_check_pressed(ord("-"))) {$(13_10)    grid_speed_step(id, -1);$(13_10)}$(13_10)if (keyboard_check_pressed(vk_add) || keyboard_check_pressed(187)$(13_10)    || keyboard_check_pressed(ord("="))) {$(13_10)    grid_speed_step(id, 1);$(13_10)}$(13_10)$(13_10)// Click a log line to jump the camera to the action. The line's text is$(13_10)// matched against living squads, first by squad name, then by the type name the$(13_10)// vanilla lines speak in; a type can match several squads, in which case the$(13_10)// first living one is centred, which is ambiguity a reader can live with.$(13_10)if (_lc && (phase != GRIDPH_DEPLOY)$(13_10)    && point_in_rectangle(_mgx, _mgy, GRIDC_BF_X1 + 4, GRIDC_LOG_Y1, GRIDC_BF_X2, GRIDC_LOG_Y2)) {$(13_10)    var _li = floor((_mgy - GRIDC_LOG_Y1) / log.log_line_height);$(13_10)    var _tot = array_length(log.__log_history);$(13_10)    var _st0 = max(0, _tot - log.log_view_lines - log.__log_scroll);$(13_10)    var _idx = _st0 + _li;$(13_10)    if ((_idx >= 0) && (_idx < _tot)) {$(13_10)        var _lt = string_lower(string(log.__log_history[_idx].text));$(13_10)        var _jump = -1;$(13_10)        for (var _js = 0; (_js < array_length(squads)) && (_jump < 0); _js++) {$(13_10)            var _jq = squads[_js];$(13_10)            if (!_jq.alive || !_jq.deployed) {$(13_10)                continue;$(13_10)            }$(13_10)            if (string_pos(string_lower(_jq.name), _lt) > 0) {$(13_10)                _jump = _js;$(13_10)            }$(13_10)        }$(13_10)        for (var _jt = 0; (_jt < array_length(squads)) && (_jump < 0); _jt++) {$(13_10)            var _jq2 = squads[_jt];$(13_10)            if (!_jq2.alive || !_jq2.deployed) {$(13_10)                continue;$(13_10)            }$(13_10)            if (string_pos(string_lower(_jq2.disp), _lt) > 0) {$(13_10)                _jump = _jt;$(13_10)            }$(13_10)        }$(13_10)        if (_jump >= 0) {$(13_10)            var _jp = grid_tile_px(id);$(13_10)            view_x = squads[_jump].col * _jp - ((GRIDC_BF_X2 - GRIDC_BF_X1) div 2);$(13_10)            view_y = squads[_jump].row * _jp - ((GRIDC_BF_Y2 - GRIDC_BF_Y1) div 2);$(13_10)            grid_clamp_view(id);$(13_10)        }$(13_10)    }$(13_10)}$(13_10)$(13_10)// Dwell timer for the tile tooltip: it resets the moment the cursor moves to a$(13_10)// different tile, so it only fires when you actually stop on something.$(13_10)if ((hover_c == hover_last_c) && (hover_r == hover_last_r) && (hover_c >= 0)) {$(13_10)    hover_time += 1;$(13_10)} else {$(13_10)    hover_time = 0;$(13_10)    hover_last_c = hover_c;$(13_10)    hover_last_r = hover_r;$(13_10)}$(13_10)$(13_10)if (keyboard_check_pressed(ord("L"))) {$(13_10)    show_legend = !show_legend;$(13_10)}$(13_10)$(13_10)// Floating combat text drifts and fades every frame, independent of sim speed,$(13_10)// pause, popups, and the end screen; hit flashes decay alongside it.$(13_10)for (var _fu = array_length(floaters) - 1; _fu >= 0; _fu--) {$(13_10)    var _fe = floaters[_fu];$(13_10)    _fe.frise += GRIDC_FLOAT_RISE;$(13_10)    _fe.flife -= 1;$(13_10)    if (_fe.flife <= 0) {$(13_10)        array_delete(floaters, _fu, 1);$(13_10)    }$(13_10)}$(13_10)for (var _hf = 0; _hf < array_length(squads); _hf++) {$(13_10)    if (squads[_hf].hit_flash > 0) {$(13_10)        squads[_hf].hit_flash -= 1;$(13_10)    }$(13_10)}$(13_10)for (var _su = array_length(shots) - 1; _su >= 0; _su--) {$(13_10)    shots[_su].life -= 1;$(13_10)    if (shots[_su].life <= 0) {$(13_10)        array_delete(shots, _su, 1);$(13_10)    }$(13_10)}$(13_10)$(13_10)if (phase == GRIDPH_END) {$(13_10)    if (_lc && point_in_rectangle(_mgx, _mgy, 660, 560, 940, 616)) {$(13_10)        grid_exit(id);$(13_10)    }$(13_10)    exit;$(13_10)}$(13_10)$(13_10)hover_c = grid_mouse_col(id, _mgx);$(13_10)hover_r = grid_mouse_row(id, _mgy);$(13_10)if (!grid_in_viewport(_mgx, _mgy) || !grid_in_bounds(id, hover_c, hover_r)) {$(13_10)    hover_c = -1;$(13_10)    hover_r = -1;$(13_10)}$(13_10)$(13_10)// ---------------------------------------------------------------------------$(13_10)// Deployment popup.$(13_10)// ---------------------------------------------------------------------------$(13_10)if (popup_open) {$(13_10)    var _pr = grid_popup_rect();$(13_10)    var _px = _pr[0];$(13_10)    var _py = _pr[1];$(13_10)    var _pw = _pr[2] - _pr[0];$(13_10)    var _ph = _pr[3] - _pr[1];$(13_10)    var _pool = grid_pool_indices(id, popup_type);$(13_10)    var _rows_vis = 8;$(13_10)    var _maxs = max(0, array_length(_pool) - _rows_vis);$(13_10)    if (mouse_wheel_up()) {$(13_10)        popup_scroll = max(0, popup_scroll - 1);$(13_10)    }$(13_10)    if (mouse_wheel_down()) {$(13_10)        popup_scroll = min(_maxs, popup_scroll + 1);$(13_10)    }$(13_10)    if (_rc || (_lc && !point_in_rectangle(_mgx, _mgy, _px, _py, _px + _pw, _py + _ph))) {$(13_10)        popup_open = false;$(13_10)        grid_clear_picks(id);$(13_10)        exit;$(13_10)    }$(13_10)    if (_lc) {$(13_10)        for (var _i = 0; _i < _rows_vis; _i++) {$(13_10)            var _idx = popup_scroll + _i;$(13_10)            if (_idx >= array_length(_pool)) {$(13_10)                break;$(13_10)            }$(13_10)            var _ry = _py + 52 + _i * 56;$(13_10)            if (point_in_rectangle(_mgx, _mgy, _px + 8, _ry, _px + _pw - 8, _ry + 52)) {$(13_10)                var _sq = squads[_pool[_idx]];$(13_10)                if (_sq.picked) {$(13_10)                    _sq.picked = false;$(13_10)                } else {$(13_10)                    var _ps0 = grid_picked_stats(id);$(13_10)                    var _room0 = combat_width - grid_deployed_count(id);$(13_10)                    if (_ps0.n >= _room0) {$(13_10)                        grid_log(id, $"Only {_room0} squads still fit on the line.", eMSG_COLOR.YELLOW);$(13_10)                    } else {$(13_10)                        _sq.picked = true;$(13_10)                    }$(13_10)                }$(13_10)            }$(13_10)        }$(13_10)        var _ps = grid_picked_stats(id);$(13_10)        if ((_ps.n > 0) && point_in_rectangle(_mgx, _mgy, _px + _pw - 190, _py + _ph - 58, _px + _pw - 14, _py + _ph - 12)) {$(13_10)            placing_list = grid_picked_indices(id);$(13_10)            placing_w = max(1, ceil(sqrt(array_length(placing_list))));$(13_10)            popup_open = false;$(13_10)            placing = true;$(13_10)        }$(13_10)    }$(13_10)    exit;$(13_10)}$(13_10)$(13_10)// ---------------------------------------------------------------------------$(13_10)// Placing a block. Wheel reshapes it, R rotates it.$(13_10)// ---------------------------------------------------------------------------$(13_10)if (placing) {$(13_10)    var _pln = array_length(placing_list);$(13_10)    if (mouse_wheel_up()) {$(13_10)        placing_w = min(max(1, _pln), placing_w + 1);$(13_10)    }$(13_10)    if (mouse_wheel_down()) {$(13_10)        placing_w = max(1, placing_w - 1);$(13_10)    }$(13_10)    if (keyboard_check_pressed(ord("R"))) {$(13_10)        placing_w = clamp(ceil(_pln / max(1, placing_w)), 1, max(1, _pln));$(13_10)    }$(13_10)    if (_rc || keyboard_check_pressed(vk_escape)) {$(13_10)        placing = false;$(13_10)        placing_list = [];$(13_10)        grid_clear_picks(id);$(13_10)        exit;$(13_10)    }$(13_10)    // Drag out the front rank the way a Total War player would: press where the$(13_10)    // line starts, release where it ends, and the block forms along it. A plain$(13_10)    // click with no drag still drops the old rectangle, so nothing that worked$(13_10)    // before stops working.$(13_10)    if (_lc && (hover_c >= 0)) {$(13_10)        place_drag = true;$(13_10)        place_c0 = hover_c;$(13_10)        place_r0 = hover_r;$(13_10)    }$(13_10)    if (place_drag && _lrel) {$(13_10)        place_drag = false;$(13_10)        var _put = false;$(13_10)        if (place_c0 >= 0) {$(13_10)            if ((hover_c >= 0) && ((hover_c != place_c0) || (hover_r != place_r0))) {$(13_10)                _put = grid_place_formation_slots(id, grid_drag_slots(id, place_c0, place_r0, hover_c, hover_r, _pln));$(13_10)            } else {$(13_10)                _put = grid_place_formation(id, place_c0, place_r0);$(13_10)            }$(13_10)        }$(13_10)        if (!_put) {$(13_10)            grid_log(id, "Cannot deploy there.", eMSG_COLOR.YELLOW);$(13_10)        }$(13_10)        place_c0 = -1;$(13_10)        place_r0 = -1;$(13_10)    }$(13_10)    if (place_drag && !_lheld) {$(13_10)        place_drag = false;$(13_10)        place_c0 = -1;$(13_10)        place_r0 = -1;$(13_10)    }$(13_10)    exit;$(13_10)}$(13_10)$(13_10)// ---------------------------------------------------------------------------$(13_10)// Buttons.$(13_10)// ---------------------------------------------------------------------------$(13_10)var _consumed = false;$(13_10)// Right click on a button counts too: the speed button steps backwards on it.$(13_10)if (_lc || _rc) {$(13_10)    var _btns = grid_buttons(id);$(13_10)    for (var _bi = 0; _bi < array_length(_btns); _bi++) {$(13_10)        var _bt = _btns[_bi];$(13_10)        if (!_bt.benabled) {$(13_10)            continue;$(13_10)        }$(13_10)        if (!point_in_rectangle(_mgx, _mgy, _bt.bx, _bt.by, _bt.bx + _bt.bw, _bt.by + _bt.bh)) {$(13_10)            continue;$(13_10)        }$(13_10)        _consumed = true;$(13_10)        var _bid = _bt.bid;$(13_10)        if (string_copy(_bid, 1, 5) == "type:") {$(13_10)            popup_type = string_delete(_bid, 1, 5);$(13_10)            popup_open = true;$(13_10)            popup_scroll = 0;$(13_10)            grid_clear_picks(id);$(13_10)        } else if (_bid == "deployall") {$(13_10)            grid_deploy_all(id);$(13_10)        } else if (_bid == "start") {$(13_10)            deployed_at_start = grid_deployed_count(id);$(13_10)            phase = GRIDPH_BATTLE;$(13_10)            grid_log(id, "Battle begins. The greenskins advance!", eMSG_COLOR.YELLOW);$(13_10)        } else if (_bid == "pause") {$(13_10)            paused = !paused;$(13_10)        } else if (_bid == "auto") {$(13_10)            auto_battle = !auto_battle;$(13_10)            grid_log(id, auto_battle$(13_10)                ? "Auto battle on: your formations will advance and fight on their own."$(13_10)                : "Auto battle off: your formations hold their current orders.", eMSG_COLOR.AQUA);$(13_10)        } else if (_bid == "legend") {$(13_10)            show_legend = !show_legend;$(13_10)        } else if (_bid == "speed") {$(13_10)            // Left click steps up, right click steps back, so nobody has to$(13_10)            // cycle all the way through max speed to slow down again.$(13_10)            grid_speed_step(id, _rc ? -1 : 1);$(13_10)        } else if (_bid == "zoom") {$(13_10)            var _kc = (hover_c >= 0) ? hover_c : floor(cols / 2);$(13_10)            var _kr = (hover_r >= 0) ? hover_r : floor(rows / 2);$(13_10)            zoom_mode = (zoom_mode == 0) ? 1 : 0;$(13_10)            grid_centre_view(id, _kc, _kr);$(13_10)        } else if (_bid == "ord_adv") {$(13_10)            for (var _oa = 0; _oa < array_length(selected); _oa++) {$(13_10)                formations[selected[_oa]].order = GRIDORD_ADVANCE;$(13_10)                formations[selected[_oa]].order_target = -1;$(13_10)            }$(13_10)            grid_log(id, "Advance and engage.", eMSG_COLOR.AQUA);$(13_10)        } else if (_bid == "ord_hold") {$(13_10)            for (var _oh = 0; _oh < array_length(selected); _oh++) {$(13_10)                formations[selected[_oh]].order = GRIDORD_HOLD;$(13_10)            }$(13_10)            grid_log(id, "Hold position.", eMSG_COLOR.AQUA);$(13_10)        } else if (_bid == "stance") {$(13_10)            for (var _os = 0; _os < array_length(selected); _os++) {$(13_10)                var _fs = formations[selected[_os]];$(13_10)                _fs.stance = (_fs.stance + 1) mod 3;$(13_10)            }$(13_10)            if (array_length(selected) > 0) {$(13_10)                var _sv = formations[selected[0]].stance;$(13_10)                var _sl = (_sv == 1) ? "seek melee" : ((_sv == 2) ? "avoid melee" : "melee at will");$(13_10)                grid_log(id, $"Stance: {_sl}.", eMSG_COLOR.AQUA);$(13_10)            }$(13_10)        } else if (_bid == "exit") {$(13_10)            if (exit_arm > 0) {$(13_10)                grid_exit(id);$(13_10)                exit;$(13_10)            }$(13_10)            exit_arm = 90;$(13_10)            if (pending_live) {$(13_10)                grid_log(id, "Withdrawing hands the field to the enemy and is recorded as a defeat. Click again to confirm.", eMSG_COLOR.YELLOW);$(13_10)            } else {$(13_10)                grid_log(id, "Click Exit again to leave the prototype.", eMSG_COLOR.YELLOW);$(13_10)            }$(13_10)        }$(13_10)        break;$(13_10)    }$(13_10)}$(13_10)$(13_10)// ---------------------------------------------------------------------------$(13_10)// Battlefield: left selects and drags, right commands. Standard RTS handling.$(13_10)// ---------------------------------------------------------------------------$(13_10)if (!_consumed && grid_in_viewport(_mgx, _mgy)) {$(13_10)    if (_lc) {$(13_10)        drag_active = true;$(13_10)        drag_x0 = _mgx;$(13_10)        drag_y0 = _mgy;$(13_10)    }$(13_10)    // Right press arms a shape drag. Released on the spot it is the old point$(13_10)    // order; dragged out it lays the selection down in the shape drawn, exactly$(13_10)    // the deployment gesture. Nothing is decided until release, so the previous$(13_10)    // right-click behaviour is untouched for anyone who never drags.$(13_10)    if (_rc && (hover_c >= 0)) {$(13_10)        ord_drag = true;$(13_10)        ord_c0 = hover_c;$(13_10)        ord_r0 = hover_r;$(13_10)    }$(13_10)}$(13_10)$(13_10)if (ord_drag && _rrel) {$(13_10)    ord_drag = false;$(13_10)    var _sqn = array_length(grid_selected_squads(id));$(13_10)    var _dragged = (hover_c >= 0) && ((hover_c != ord_c0) || (hover_r != ord_r0));$(13_10)    if (_dragged && (_sqn > 1)) {$(13_10)        var _osl = grid_drag_slots(id, ord_c0, ord_r0, hover_c, hover_r, _sqn, ord_depth);$(13_10)        grid_order_shape(id, _osl);$(13_10)    } else if (ord_c0 >= 0) {$(13_10)        // Point order, as before.$(13_10)        var _hit = grid_squad_at(id, ord_c0, ord_r0);$(13_10)        if ((_hit >= 0) && (squads[_hit].side == 1) && (array_length(selected) > 0)) {$(13_10)            grid_order_attack(id, _hit);$(13_10)            grid_log(id, $"Concentrate fire on {squads[_hit].name}!", eMSG_COLOR.AQUA);$(13_10)        } else if ((_hit >= 0) && (squads[_hit].side == 0) && (phase == GRIDPH_DEPLOY)) {$(13_10)            grid_undeploy_formation(id, squads[_hit].formation);$(13_10)            grid_sel_prune(id);$(13_10)        } else if (array_length(selected) > 0) {$(13_10)            grid_order_move(id, ord_c0, ord_r0);$(13_10)            if (array_length(selected) > 1) {$(13_10)                grid_log(id, $"{array_length(selected)} formations advance on {ord_c0}, {ord_r0} in formation.", eMSG_COLOR.AQUA);$(13_10)            } else {$(13_10)                grid_log(id, $"Move to {ord_c0}, {ord_r0}.", eMSG_COLOR.AQUA);$(13_10)            }$(13_10)        }$(13_10)    }$(13_10)    ord_c0 = -1;$(13_10)    ord_r0 = -1;$(13_10)}$(13_10)if (ord_drag && !_rheld) {$(13_10)    ord_drag = false;$(13_10)    ord_c0 = -1;$(13_10)    ord_r0 = -1;$(13_10)}$(13_10)$(13_10)// R reshapes the drag in flight, the same key deployment uses. X breaks the$(13_10)// selection into individually commandable squads.$(13_10)if (ord_drag && keyboard_check_pressed(ord("R"))) {$(13_10)    ord_depth = (ord_depth >= 4) ? 1 : (ord_depth + 1);$(13_10)}$(13_10)if (keyboard_check_pressed(ord("X")) && (phase != GRIDPH_END)) {$(13_10)    grid_split_selection(id);$(13_10)}$(13_10)$(13_10)if (drag_active && _lrel) {$(13_10)    drag_active = false;$(13_10)    // Every outcome is reported, including the empty ones. Silence on a failed$(13_10)    // selection is indistinguishable from the input never arriving.$(13_10)    if (point_distance(drag_x0, drag_y0, _mgx, _mgy) >= GRIDC_DRAG_MIN) {$(13_10)        var _n = grid_sel_box(id, drag_x0, drag_y0, _mgx, _mgy);$(13_10)        if (_n > 0) {$(13_10)            grid_log(id, $"{_n} formations selected.", eMSG_COLOR.AQUA);$(13_10)        } else {$(13_10)            grid_log(id, "Nothing in the box: selection cleared.", eMSG_COLOR.YELLOW);$(13_10)        }$(13_10)    } else {$(13_10)        var _pick = grid_squad_at(id, hover_c, hover_r);$(13_10)        if ((_pick >= 0) && (squads[_pick].side == 0) && (squads[_pick].formation >= 0)$(13_10)            && keyboard_check(vk_alt)) {$(13_10)            // Alt click takes one squad out of its block and selects only it.$(13_10)            var _one = grid_split_squad(id, _pick);$(13_10)            grid_sel_clear(id);$(13_10)            grid_sel_add(id, _one);$(13_10)            grid_log(id, $"{squads[_pick].name} detached.", eMSG_COLOR.AQUA);$(13_10)        } else if ((_pick >= 0) && (squads[_pick].side == 0) && (squads[_pick].formation >= 0)) {$(13_10)            grid_sel_clear(id);$(13_10)            grid_sel_add(id, squads[_pick].formation);$(13_10)            grid_log(id, $"{formations[squads[_pick].formation].name} selected.", eMSG_COLOR.AQUA);$(13_10)        } else {$(13_10)            grid_sel_clear(id);$(13_10)            grid_log(id, "Selection cleared.", eMSG_COLOR.YELLOW);$(13_10)        }$(13_10)    }$(13_10)}$(13_10)if (drag_active && !_lheld) {$(13_10)    drag_active = false;$(13_10)}$(13_10)$(13_10)grid_sel_prune(id);$(13_10)$(13_10)$(13_10)// Control groups. Ctrl and a number binds the current selection, the number on$(13_10)// its own recalls it, which is what every RTS has trained hands to expect.$(13_10)var _ctrl_held = keyboard_check(vk_control);$(13_10)for (var _gk = 0; _gk <= 9; _gk++) {$(13_10)    if (!keyboard_check_pressed(ord(string(_gk)))) {$(13_10)        continue;$(13_10)    }$(13_10)    if (_ctrl_held) {$(13_10)        grid_group_bind(id, _gk);$(13_10)    } else {$(13_10)        var _gn = grid_group_recall(id, _gk);$(13_10)        if (_gn > 0) {$(13_10)            grid_log(id, $"Group {_gk} selected: {_gn} formations.", eMSG_COLOR.AQUA);$(13_10)        }$(13_10)    }$(13_10)}$(13_10)$(13_10)// Battlefield wide orders on the function keys. Deliberately keyboard only: the$(13_10)// letter keys are taken by panning, the number keys by control groups, and I$(13_10)// cannot verify new button placement against a live screen. They are listed in$(13_10)// the legend and in the opening log.$(13_10)if (phase == GRIDPH_BATTLE) {$(13_10)    if (keyboard_check_pressed(vk_f1)) {$(13_10)        grid_battle_plan(id, "hold");$(13_10)    }$(13_10)    if (keyboard_check_pressed(vk_f2)) {$(13_10)        grid_battle_plan(id, "line");$(13_10)    }$(13_10)    if (keyboard_check_pressed(vk_f3)) {$(13_10)        grid_battle_plan(id, "advance");$(13_10)    }$(13_10)    if (keyboard_check_pressed(vk_f4)) {$(13_10)        grid_battle_plan(id, "advhold");$(13_10)    }$(13_10)    if (keyboard_check_pressed(vk_f5)) {$(13_10)        grid_battle_plan(id, "charge");$(13_10)    }$(13_10)    if (keyboard_check_pressed(vk_f6)) {$(13_10)        grid_battle_plan(id, "fallback");$(13_10)    }$(13_10)}$(13_10)$(13_10)if ((phase == GRIDPH_BATTLE) && keyboard_check_pressed(vk_space)) {$(13_10)    paused = !paused;$(13_10)}$(13_10)$(13_10)// ---------------------------------------------------------------------------$(13_10)// Simulation clock.$(13_10)// ---------------------------------------------------------------------------$(13_10)if ((phase == GRIDPH_BATTLE) && !paused && !popup_open && !placing) {$(13_10)    frame_ctr += speed_mult;$(13_10)    while (frame_ctr >= GRIDC_TICK_FRAMES) {$(13_10)        frame_ctr -= GRIDC_TICK_FRAMES;$(13_10)        grid_battle_tick(id);$(13_10)        if (phase != GRIDPH_BATTLE) {$(13_10)            break;$(13_10)        }$(13_10)    }$(13_10)}$(13_10)"
/// @description Input, camera, and the simulation clock.

var _mgx = device_mouse_x_to_gui(0);
var _mgy = device_mouse_y_to_gui(0);
var _lc = mouse_check_button_pressed(mb_left);
var _rc = mouse_check_button_pressed(mb_right);
var _lheld = mouse_check_button(mb_left);
var _lrel = mouse_check_button_released(mb_left);
var _rheld = mouse_check_button(mb_right);
var _rrel = mouse_check_button_released(mb_right);

if (!boot_done) {
    boot_done = true;
    instance_deactivate_all(true);
    // instance_exists cannot see deactivated instances, so a guard here would
    // always fail and leave the cursor frozen. Unconditional activation is a
    // safe no-op if no cursor instance is around.
    instance_activate_object(obj_cursor);
	instance_activate_object(obj_ncombat);

    grid_setup_field(id, pending_width);
    grid_gen_structures(id);
    grid_gen_cover(id);
    // A bigger fight keeps coming for longer, so the wave count follows threat
    // rather than sitting at the prototype's flat one.
    waves_left = clamp(round(clamp(pending_threat, 1, 7) / 2), 1, 4);
    if (array_length(pending_force) > 0) {
        grid_import_force(id, pending_force);
    } else {
        grid_gen_player_pool(id);
    }
    grid_spawn_enemy_force(id);
    grid_centre_view(id, GRIDC_DEPLOY_COLS, floor(rows / 2));
    if (pending_loc != "") {
        grid_log(id, $"Battle for {pending_loc}.", eMSG_COLOR.BRIGHT_BLUE);
    }
    grid_log(id, $"Deployment: up to {GRIDC_PLAYER_DEPLOY_CAP} squads, six lines deep, laid out by your formation settings.", eMSG_COLOR.BRIGHT_BLUE);
    if (pending_live) {
        grid_log(id, "Live battle: these are your real companies and your losses are permanent.", eMSG_COLOR.YELLOW);
    }
    grid_log(id, "Left click selects, drag a box to select several, right click orders.", eMSG_COLOR.AQUA);
    grid_log(id, "Deploying: drag out the front rank and the block forms along it.", eMSG_COLOR.AQUA);
    grid_log(id, "Ctrl and a number binds a control group, the number recalls it.", eMSG_COLOR.AQUA);
    grid_log(id, "Right click drag places the selection in a shape. R sets ranks, X breaks a block up.", eMSG_COLOR.AQUA);
    grid_log(id, "Chapter orders: F1 hold, F2 fire line, F3 advance, F4 advance and hold, F5 assault, F6 fall back.", eMSG_COLOR.AQUA);
    grid_log(id, "WASD pans the field. Tab toggles the overview.", eMSG_COLOR.AQUA);
}

if (exit_arm > 0) {
    exit_arm -= 1;
}

// Scrollback over the log strip, same wheel and scrollbar handling as a vanilla
// battle. Scoped to the strip, so it never competes with the deployment popup's
// own wheel scrolling.
log.update_scroll(GRIDC_BF_X1 + 4, GRIDC_LOG_Y1, GRIDC_BF_X2 - GRIDC_BF_X1, GRIDC_LOG_Y2 - GRIDC_LOG_Y1);

// ---------------------------------------------------------------------------
// Camera and view keys. These run before the deployment popup and the placing
// handler, both of which exit the event early. Sitting after them meant the
// camera was frozen for the whole of deployment: you could not look at the
// ground you were being asked to deploy onto. Nothing here touches game state,
// so it is safe at the top.
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Camera and hotkeys.
// ---------------------------------------------------------------------------
if (keyboard_check(ord("A")) || keyboard_check(vk_left)) {
    view_x -= GRIDC_SCROLL_SPEED;
}
if (keyboard_check(ord("D")) || keyboard_check(vk_right)) {
    view_x += GRIDC_SCROLL_SPEED;
}
if (keyboard_check(ord("W")) || keyboard_check(vk_up)) {
    view_y -= GRIDC_SCROLL_SPEED;
}
if (keyboard_check(ord("S")) || keyboard_check(vk_down)) {
    view_y += GRIDC_SCROLL_SPEED;
}
grid_clamp_view(id);

if (keyboard_check_pressed(vk_tab)) {
    var _tc = (hover_c >= 0) ? hover_c : floor(cols / 2);
    var _tr = (hover_r >= 0) ? hover_r : floor(rows / 2);
    zoom_mode = (zoom_mode == 0) ? 1 : 0;
    grid_centre_view(id, _tc, _tr);
}

// Minus and plus step the clock, on both the main row and the numpad.
if (keyboard_check_pressed(vk_subtract) || keyboard_check_pressed(189)
    || keyboard_check_pressed(ord("-"))) {
    grid_speed_step(id, -1);
}
if (keyboard_check_pressed(vk_add) || keyboard_check_pressed(187)
    || keyboard_check_pressed(ord("="))) {
    grid_speed_step(id, 1);
}

// Click a log line to jump the camera to the action. The line's text is
// matched against living squads, first by squad name, then by the type name the
// vanilla lines speak in; a type can match several squads, in which case the
// first living one is centred, which is ambiguity a reader can live with.
if (_lc && (phase != GRIDPH_DEPLOY)
    && point_in_rectangle(_mgx, _mgy, GRIDC_BF_X1 + 4, GRIDC_LOG_Y1, GRIDC_BF_X2, GRIDC_LOG_Y2)) {
    var _li = floor((_mgy - GRIDC_LOG_Y1) / log.log_line_height);
    var _tot = array_length(log.__log_history);
    var _st0 = max(0, _tot - log.log_view_lines - log.__log_scroll);
    var _idx = _st0 + _li;
    if ((_idx >= 0) && (_idx < _tot)) {
        var _lt = string_lower(string(log.__log_history[_idx].text));
        var _jump = -1;
        for (var _js = 0; (_js < array_length(squads)) && (_jump < 0); _js++) {
            var _jq = squads[_js];
            if (!_jq.alive || !_jq.deployed) {
                continue;
            }
            if (string_pos(string_lower(_jq.name), _lt) > 0) {
                _jump = _js;
            }
        }
        for (var _jt = 0; (_jt < array_length(squads)) && (_jump < 0); _jt++) {
            var _jq2 = squads[_jt];
            if (!_jq2.alive || !_jq2.deployed) {
                continue;
            }
            if (string_pos(string_lower(_jq2.disp), _lt) > 0) {
                _jump = _jt;
            }
        }
        if (_jump >= 0) {
            var _jp = grid_tile_px(id);
            view_x = squads[_jump].col * _jp - ((GRIDC_BF_X2 - GRIDC_BF_X1) div 2);
            view_y = squads[_jump].row * _jp - ((GRIDC_BF_Y2 - GRIDC_BF_Y1) div 2);
            grid_clamp_view(id);
        }
    }
}

// Dwell timer for the tile tooltip: it resets the moment the cursor moves to a
// different tile, so it only fires when you actually stop on something.
if ((hover_c == hover_last_c) && (hover_r == hover_last_r) && (hover_c >= 0)) {
    hover_time += 1;
} else {
    hover_time = 0;
    hover_last_c = hover_c;
    hover_last_r = hover_r;
}

if (keyboard_check_pressed(ord("L"))) {
    show_legend = !show_legend;
}

// Floating combat text drifts and fades every frame, independent of sim speed,
// pause, popups, and the end screen; hit flashes decay alongside it.
for (var _fu = array_length(floaters) - 1; _fu >= 0; _fu--) {
    var _fe = floaters[_fu];
    _fe.frise += GRIDC_FLOAT_RISE;
    _fe.flife -= 1;
    if (_fe.flife <= 0) {
        array_delete(floaters, _fu, 1);
    }
}
for (var _hf = 0; _hf < array_length(squads); _hf++) {
    if (squads[_hf].hit_flash > 0) {
        squads[_hf].hit_flash -= 1;
    }
}
for (var _su = array_length(shots) - 1; _su >= 0; _su--) {
    shots[_su].life -= 1;
    if (shots[_su].life <= 0) {
        array_delete(shots, _su, 1);
    }
}

if (phase == GRIDPH_END) {
    if (_lc && point_in_rectangle(_mgx, _mgy, 660, 560, 940, 616)) {
        grid_exit(id);
    }
    exit;
}

hover_c = grid_mouse_col(id, _mgx);
hover_r = grid_mouse_row(id, _mgy);
if (!grid_in_viewport(_mgx, _mgy) || !grid_in_bounds(id, hover_c, hover_r)) {
    hover_c = -1;
    hover_r = -1;
}

// ---------------------------------------------------------------------------
// Deployment popup.
// ---------------------------------------------------------------------------
if (popup_open) {
    var _pr = grid_popup_rect();
    var _px = _pr[0];
    var _py = _pr[1];
    var _pw = _pr[2] - _pr[0];
    var _ph = _pr[3] - _pr[1];
    var _pool = grid_pool_indices(id, popup_type);
    var _rows_vis = 8;
    var _maxs = max(0, array_length(_pool) - _rows_vis);
    if (mouse_wheel_up()) {
        popup_scroll = max(0, popup_scroll - 1);
    }
    if (mouse_wheel_down()) {
        popup_scroll = min(_maxs, popup_scroll + 1);
    }
    if (_rc || (_lc && !point_in_rectangle(_mgx, _mgy, _px, _py, _px + _pw, _py + _ph))) {
        popup_open = false;
        grid_clear_picks(id);
        exit;
    }
    if (_lc) {
        for (var _i = 0; _i < _rows_vis; _i++) {
            var _idx = popup_scroll + _i;
            if (_idx >= array_length(_pool)) {
                break;
            }
            var _ry = _py + 52 + _i * 56;
            if (point_in_rectangle(_mgx, _mgy, _px + 8, _ry, _px + _pw - 8, _ry + 52)) {
                var _sq = squads[_pool[_idx]];
                if (_sq.picked) {
                    _sq.picked = false;
                } else {
                    var _ps0 = grid_picked_stats(id);
                    var _room0 = combat_width - grid_deployed_count(id);
                    if (_ps0.n >= _room0) {
                        grid_log(id, $"Only {_room0} squads still fit on the line.", eMSG_COLOR.YELLOW);
                    } else {
                        _sq.picked = true;
                    }
                }
            }
        }
        var _ps = grid_picked_stats(id);
        if ((_ps.n > 0) && point_in_rectangle(_mgx, _mgy, _px + _pw - 190, _py + _ph - 58, _px + _pw - 14, _py + _ph - 12)) {
            placing_list = grid_picked_indices(id);
            placing_w = max(1, ceil(sqrt(array_length(placing_list))));
            popup_open = false;
            placing = true;
        }
    }
    exit;
}

// ---------------------------------------------------------------------------
// Placing a block. Wheel reshapes it, R rotates it.
// ---------------------------------------------------------------------------
if (placing) {
    var _pln = array_length(placing_list);
    if (mouse_wheel_up()) {
        placing_w = min(max(1, _pln), placing_w + 1);
    }
    if (mouse_wheel_down()) {
        placing_w = max(1, placing_w - 1);
    }
    if (keyboard_check_pressed(ord("R"))) {
        placing_w = clamp(ceil(_pln / max(1, placing_w)), 1, max(1, _pln));
    }
    if (_rc || keyboard_check_pressed(vk_escape)) {
        placing = false;
        placing_list = [];
        grid_clear_picks(id);
        exit;
    }
    // Drag out the front rank the way a Total War player would: press where the
    // line starts, release where it ends, and the block forms along it. A plain
    // click with no drag still drops the old rectangle, so nothing that worked
    // before stops working.
    if (_lc && (hover_c >= 0)) {
        place_drag = true;
        place_c0 = hover_c;
        place_r0 = hover_r;
    }
    if (place_drag && _lrel) {
        place_drag = false;
        var _put = false;
        if (place_c0 >= 0) {
            if ((hover_c >= 0) && ((hover_c != place_c0) || (hover_r != place_r0))) {
                _put = grid_place_formation_slots(id, grid_drag_slots(id, place_c0, place_r0, hover_c, hover_r, _pln));
            } else {
                _put = grid_place_formation(id, place_c0, place_r0);
            }
        }
        if (!_put) {
            grid_log(id, "Cannot deploy there.", eMSG_COLOR.YELLOW);
        }
        place_c0 = -1;
        place_r0 = -1;
    }
    if (place_drag && !_lheld) {
        place_drag = false;
        place_c0 = -1;
        place_r0 = -1;
    }
    exit;
}

// ---------------------------------------------------------------------------
// Buttons.
// ---------------------------------------------------------------------------
var _consumed = false;
// Right click on a button counts too: the speed button steps backwards on it.
if (_lc || _rc) {
    var _btns = grid_buttons(id);
    for (var _bi = 0; _bi < array_length(_btns); _bi++) {
        var _bt = _btns[_bi];
        if (!_bt.benabled) {
            continue;
        }
        if (!point_in_rectangle(_mgx, _mgy, _bt.bx, _bt.by, _bt.bx + _bt.bw, _bt.by + _bt.bh)) {
            continue;
        }
        _consumed = true;
        var _bid = _bt.bid;
        if (string_copy(_bid, 1, 5) == "type:") {
            popup_type = string_delete(_bid, 1, 5);
            popup_open = true;
            popup_scroll = 0;
            grid_clear_picks(id);
        } else if (_bid == "deployall") {
            grid_deploy_all(id);
        } else if (_bid == "start") {
            deployed_at_start = grid_deployed_count(id);
            phase = GRIDPH_BATTLE;
            grid_log(id, "Battle begins. The greenskins advance!", eMSG_COLOR.YELLOW);
        } else if (_bid == "pause") {
            paused = !paused;
        } else if (_bid == "auto") {
            auto_battle = !auto_battle;
            grid_log(id, auto_battle
                ? "Auto battle on: your formations will advance and fight on their own."
                : "Auto battle off: your formations hold their current orders.", eMSG_COLOR.AQUA);
        } else if (_bid == "legend") {
            show_legend = !show_legend;
        } else if (_bid == "speed") {
            // Left click steps up, right click steps back, so nobody has to
            // cycle all the way through max speed to slow down again.
            grid_speed_step(id, _rc ? -1 : 1);
        } else if (_bid == "zoom") {
            var _kc = (hover_c >= 0) ? hover_c : floor(cols / 2);
            var _kr = (hover_r >= 0) ? hover_r : floor(rows / 2);
            zoom_mode = (zoom_mode == 0) ? 1 : 0;
            grid_centre_view(id, _kc, _kr);
        } else if (_bid == "ord_adv") {
            for (var _oa = 0; _oa < array_length(selected); _oa++) {
                formations[selected[_oa]].order = GRIDORD_ADVANCE;
                formations[selected[_oa]].order_target = -1;
            }
            grid_log(id, "Advance and engage.", eMSG_COLOR.AQUA);
        } else if (_bid == "ord_hold") {
            for (var _oh = 0; _oh < array_length(selected); _oh++) {
                formations[selected[_oh]].order = GRIDORD_HOLD;
            }
            grid_log(id, "Hold position.", eMSG_COLOR.AQUA);
        } else if (_bid == "stance") {
            for (var _os = 0; _os < array_length(selected); _os++) {
                var _fs = formations[selected[_os]];
                _fs.stance = (_fs.stance + 1) mod 3;
            }
            if (array_length(selected) > 0) {
                var _sv = formations[selected[0]].stance;
                var _sl = (_sv == 1) ? "seek melee" : ((_sv == 2) ? "avoid melee" : "melee at will");
                grid_log(id, $"Stance: {_sl}.", eMSG_COLOR.AQUA);
            }
        } else if (_bid == "exit") {
            if (exit_arm > 0) {
                grid_exit(id);
                exit;
            }
            exit_arm = 90;
            if (pending_live) {
                grid_log(id, "Withdrawing hands the field to the enemy and is recorded as a defeat. Click again to confirm.", eMSG_COLOR.YELLOW);
            } else {
                grid_log(id, "Click Exit again to leave the prototype.", eMSG_COLOR.YELLOW);
            }
        }
        break;
    }
}

// ---------------------------------------------------------------------------
// Battlefield: left selects and drags, right commands. Standard RTS handling.
// ---------------------------------------------------------------------------
if (!_consumed && grid_in_viewport(_mgx, _mgy)) {
    if (_lc) {
        drag_active = true;
        drag_x0 = _mgx;
        drag_y0 = _mgy;
    }
    // Right press arms a shape drag. Released on the spot it is the old point
    // order; dragged out it lays the selection down in the shape drawn, exactly
    // the deployment gesture. Nothing is decided until release, so the previous
    // right-click behaviour is untouched for anyone who never drags.
    if (_rc && (hover_c >= 0)) {
        ord_drag = true;
        ord_c0 = hover_c;
        ord_r0 = hover_r;
    }
}

if (ord_drag && _rrel) {
    ord_drag = false;
    var _sqn = array_length(grid_selected_squads(id));
    var _dragged = (hover_c >= 0) && ((hover_c != ord_c0) || (hover_r != ord_r0));
    if (_dragged && (_sqn > 1)) {
        var _osl = grid_drag_slots(id, ord_c0, ord_r0, hover_c, hover_r, _sqn, ord_depth);
        grid_order_shape(id, _osl);
    } else if (ord_c0 >= 0) {
        // Point order, as before.
        var _hit = grid_squad_at(id, ord_c0, ord_r0);
        if ((_hit >= 0) && (squads[_hit].side == 1) && (array_length(selected) > 0)) {
            grid_order_attack(id, _hit);
            grid_log(id, $"Concentrate fire on {squads[_hit].name}!", eMSG_COLOR.AQUA);
        } else if ((_hit >= 0) && (squads[_hit].side == 0) && (phase == GRIDPH_DEPLOY)) {
            grid_undeploy_formation(id, squads[_hit].formation);
            grid_sel_prune(id);
        } else if (array_length(selected) > 0) {
            grid_order_move(id, ord_c0, ord_r0);
            if (array_length(selected) > 1) {
                grid_log(id, $"{array_length(selected)} formations advance on {ord_c0}, {ord_r0} in formation.", eMSG_COLOR.AQUA);
            } else {
                grid_log(id, $"Move to {ord_c0}, {ord_r0}.", eMSG_COLOR.AQUA);
            }
        }
    }
    ord_c0 = -1;
    ord_r0 = -1;
}
if (ord_drag && !_rheld) {
    ord_drag = false;
    ord_c0 = -1;
    ord_r0 = -1;
}

// R reshapes the drag in flight, the same key deployment uses. X breaks the
// selection into individually commandable squads.
if (ord_drag && keyboard_check_pressed(ord("R"))) {
    ord_depth = (ord_depth >= 4) ? 1 : (ord_depth + 1);
}
if (keyboard_check_pressed(ord("X")) && (phase != GRIDPH_END)) {
    grid_split_selection(id);
}

if (drag_active && _lrel) {
    drag_active = false;
    // Every outcome is reported, including the empty ones. Silence on a failed
    // selection is indistinguishable from the input never arriving.
    if (point_distance(drag_x0, drag_y0, _mgx, _mgy) >= GRIDC_DRAG_MIN) {
        var _n = grid_sel_box(id, drag_x0, drag_y0, _mgx, _mgy);
        if (_n > 0) {
            grid_log(id, $"{_n} formations selected.", eMSG_COLOR.AQUA);
        } else {
            grid_log(id, "Nothing in the box: selection cleared.", eMSG_COLOR.YELLOW);
        }
    } else {
        var _pick = grid_squad_at(id, hover_c, hover_r);
        if ((_pick >= 0) && (squads[_pick].side == 0) && (squads[_pick].formation >= 0)
            && keyboard_check(vk_alt)) {
            // Alt click takes one squad out of its block and selects only it.
            var _one = grid_split_squad(id, _pick);
            grid_sel_clear(id);
            grid_sel_add(id, _one);
            grid_log(id, $"{squads[_pick].name} detached.", eMSG_COLOR.AQUA);
        } else if ((_pick >= 0) && (squads[_pick].side == 0) && (squads[_pick].formation >= 0)) {
            grid_sel_clear(id);
            grid_sel_add(id, squads[_pick].formation);
            grid_log(id, $"{formations[squads[_pick].formation].name} selected.", eMSG_COLOR.AQUA);
        } else {
            grid_sel_clear(id);
            grid_log(id, "Selection cleared.", eMSG_COLOR.YELLOW);
        }
    }
}
if (drag_active && !_lheld) {
    drag_active = false;
}

grid_sel_prune(id);


// Control groups. Ctrl and a number binds the current selection, the number on
// its own recalls it, which is what every RTS has trained hands to expect.
var _ctrl_held = keyboard_check(vk_control);
for (var _gk = 0; _gk <= 9; _gk++) {
    if (!keyboard_check_pressed(ord(string(_gk)))) {
        continue;
    }
    if (_ctrl_held) {
        grid_group_bind(id, _gk);
    } else {
        var _gn = grid_group_recall(id, _gk);
        if (_gn > 0) {
            grid_log(id, $"Group {_gk} selected: {_gn} formations.", eMSG_COLOR.AQUA);
        }
    }
}

// Battlefield wide orders on the function keys. Deliberately keyboard only: the
// letter keys are taken by panning, the number keys by control groups, and I
// cannot verify new button placement against a live screen. They are listed in
// the legend and in the opening log.
if (phase == GRIDPH_BATTLE) {
    if (keyboard_check_pressed(vk_f1)) {
        grid_battle_plan(id, "hold");
    }
    if (keyboard_check_pressed(vk_f2)) {
        grid_battle_plan(id, "line");
    }
    if (keyboard_check_pressed(vk_f3)) {
        grid_battle_plan(id, "advance");
    }
    if (keyboard_check_pressed(vk_f4)) {
        grid_battle_plan(id, "advhold");
    }
    if (keyboard_check_pressed(vk_f5)) {
        grid_battle_plan(id, "charge");
    }
    if (keyboard_check_pressed(vk_f6)) {
        grid_battle_plan(id, "fallback");
    }
}

if ((phase == GRIDPH_BATTLE) && keyboard_check_pressed(vk_space)) {
    paused = !paused;
}

// ---------------------------------------------------------------------------
// Simulation clock.
// ---------------------------------------------------------------------------
if ((phase == GRIDPH_BATTLE) && !paused && !popup_open && !placing) {
    frame_ctr += speed_mult;
    while (frame_ctr >= GRIDC_TICK_FRAMES) {
        frame_ctr -= GRIDC_TICK_FRAMES;
        grid_battle_tick(id);
        if (phase != GRIDPH_BATTLE) {
            break;
        }
    }
}