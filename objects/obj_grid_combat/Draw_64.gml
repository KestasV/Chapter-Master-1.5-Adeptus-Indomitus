/// @description All rendering. Fixed 1600x900 GUI, vanilla green on black.

// The field is built in the first Step; Draw can fire before that on the frame
// the object is created, so there is nothing to render yet.
if (!boot_done) {
    exit;
}

var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _tp = grid_tile_px(id);

draw_set_alpha(1);
draw_set_font(fnt_40k_14);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// backdrop
draw_set_color(GRIDC_BG);
draw_rectangle(0, 0, 1600, 900, false);

// title bar
draw_set_color(GRIDC_GREEN);
draw_rectangle(GRIDC_LP_X1, 8, GRIDC_RP_X2, 48, true);
var _ph_name = (phase == GRIDPH_DEPLOY) ? "Deployment" : ((phase == GRIDPH_BATTLE) ? "Battle" : "Resolved");
draw_text(GRIDC_LP_X1 + 10, 16, $"Grid Combat ( Front {combat_width} ) - {_ph_name} - Tick {ticks}");
draw_set_halign(fa_right);
var _online = grid_deployed_count(id);
var _inres = grid_reserve_count(id);
draw_text(GRIDC_RP_X2 - 10, 16, $"On the line {_online} / {combat_width}   Reserve {_inres}");
draw_set_halign(fa_left);

// ---------------------------------------------------------------------------
// Battlefield
// ---------------------------------------------------------------------------
draw_set_color(GRIDC_PANEL);
draw_rectangle(GRIDC_BF_X1, GRIDC_BF_Y1, GRIDC_BF_X2, GRIDC_BF_Y2, false);

var _c0 = clamp(floor(view_x / _tp), 0, max(0, cols - 1));
var _c1 = clamp(ceil((view_x + (GRIDC_BF_X2 - GRIDC_BF_X1)) / _tp), 0, cols);
var _r0 = clamp(floor(view_y / _tp), 0, max(0, rows - 1));
var _r1 = clamp(ceil((view_y + (GRIDC_BF_Y2 - GRIDC_BF_Y1)) / _tp), 0, rows);

// zone tints
draw_set_alpha(0.14);
draw_set_color(GRIDC_GREEN);
var _dzx1 = max(GRIDC_BF_X1, grid_sx(id, 0));
var _dzx2 = min(GRIDC_BF_X2, grid_sx(id, GRIDC_DEPLOY_COLS));
var _dzy1 = max(GRIDC_BF_Y1, grid_sy(id, band_r1));
var _dzy2 = min(GRIDC_BF_Y2, grid_sy(id, band_r2 + 1));
if ((_dzx2 > _dzx1) && (_dzy2 > _dzy1)) {
    draw_rectangle(_dzx1, _dzy1, _dzx2, _dzy2, false);
}
draw_set_color(GRIDC_RED);
var _ezx1 = max(GRIDC_BF_X1, grid_sx(id, cols - GRIDC_ENEMY_COLS));
var _ezx2 = min(GRIDC_BF_X2, grid_sx(id, cols));
if (_ezx2 > _ezx1) {
    draw_rectangle(_ezx1, max(GRIDC_BF_Y1, grid_sy(id, 0)), _ezx2, min(GRIDC_BF_Y2, grid_sy(id, rows)), false);
}

// grid dividers
draw_set_alpha(0.30);
draw_set_color(GRIDC_DIM);
for (var _gc = _c0; _gc <= _c1; _gc++) {
    var _gx = grid_sx(id, _gc);
    if ((_gx >= GRIDC_BF_X1) && (_gx <= GRIDC_BF_X2)) {
        draw_line(_gx, max(GRIDC_BF_Y1, grid_sy(id, 0)), _gx, min(GRIDC_BF_Y2, grid_sy(id, rows)));
    }
}
for (var _gr = _r0; _gr <= _r1; _gr++) {
    var _gy = grid_sy(id, _gr);
    if ((_gy >= GRIDC_BF_Y1) && (_gy <= GRIDC_BF_Y2)) {
        draw_line(max(GRIDC_BF_X1, grid_sx(id, 0)), _gy, min(GRIDC_BF_X2, grid_sx(id, cols)), _gy);
    }
}
draw_set_alpha(1);

// cover and structures. Structures draw at every zoom: a wall the overview
// cannot see is a battle the overview cannot explain, and units looked like
// they were avoiding empty ground for no reason. Only the cover glyphs, which
// need legible text, keep the zoom gate.
draw_set_font(fnt_tiny);
for (var _cc = _c0; _cc < _c1; _cc++) {
    for (var _cr = _r0; _cr < _r1; _cr++) {
        {
            // Structures first: a wall is a solid block, a barrier is half a
            // block, which is what tells you at a glance whether you can shoot
            // through it.
            var _bk = blk[_cc][_cr];
            if (_bk != GRIDT_OPEN) {
                var _bx = grid_sx(id, _cc);
                var _by2 = grid_sy(id, _cr);
                if (_bk == GRIDT_LIGHT) {
                    // Trees and wreckage: a scatter, not a block, so it reads as
                    // ground you can walk into rather than a wall.
                    draw_set_color(make_color_rgb(96, 140, 96));
                    draw_set_alpha(0.40);
                    draw_rectangle(_bx + 4, _by2 + 4, _bx + _tp - 4, _by2 + _tp - 4, false);
                    draw_set_alpha(0.55);
                    continue;
                }
                draw_set_color(make_color_rgb(128, 132, 128));
                draw_set_alpha((_bk == GRIDT_WALL) ? 0.85 : 0.45);
                if (_bk == GRIDT_WALL) {
                    draw_rectangle(_bx + 1, _by2 + 1, _bx + _tp - 1, _by2 + _tp - 1, false);
                } else {
                    draw_rectangle(_bx + 1, _by2 + (_tp / 2), _bx + _tp - 1, _by2 + _tp - 1, false);
                }
                draw_set_alpha(0.9);
                draw_rectangle(_bx + 1, _by2 + 1, _bx + _tp - 1, _by2 + _tp - 1, true);
                draw_set_alpha(0.55);
                continue;
            }
            var _cv = cov[_cc][_cr];
            if ((_cv == 0) || (_tp < 14)) {
                continue;
            }
            draw_set_color((_cv == 1) ? GRIDC_GREEN : GRIDC_RED);
            draw_set_alpha(0.55);
            draw_text(grid_sx(id, _cc) + 3, grid_sy(id, _cr) + 2, (_cv == 1) ? "~~" : "xx");
        }
    }
}
draw_set_alpha(1);

// Ctrl: range and line of sight for the selection. Reachable tiles wash red;
// anything a wall hides from every selected squad stays dark. Drawn under the
// units so the field stays readable through it.
if (keyboard_check(vk_control) && (array_length(selected) > 0) && (phase != GRIDPH_END)) {
    var _rsq = grid_selected_squads(id);
    draw_set_color(GRIDC_RED);
    for (var _rc2 = _c0; _rc2 < _c1; _rc2++) {
        for (var _rr2 = _r0; _rr2 < _r1; _rr2++) {
            if (blk[_rc2][_rr2] == GRIDT_WALL) {
                continue;
            }
            var _reach = false;
            for (var _rq = 0; _rq < array_length(_rsq); _rq++) {
                var _rs = squads[_rsq[_rq]];
                if (grid_dist(_rs.col, _rs.row, _rc2, _rr2) > max(1, _rs.rng)) {
                    continue;
                }
                if (grid_line_block(id, _rs.col, _rs.row, _rc2, _rr2)[0]) {
                    continue;
                }
                _reach = true;
                break;
            }
            if (_reach) {
                var _rx2 = grid_sx(id, _rc2);
                var _ry2 = grid_sy(id, _rr2);
                draw_set_alpha(0.16);
                draw_rectangle(_rx2 + 1, _ry2 + 1, _rx2 + _tp - 1, _ry2 + _tp - 1, false);
            }
        }
    }
    draw_set_alpha(1);
}

// units
for (var _ui = 0; _ui < array_length(squads); _ui++) {
    var _s = squads[_ui];
    if (!_s.alive || !_s.deployed) {
        continue;
    }
    if ((_s.col < _c0 - 1) || (_s.col > _c1) || (_s.row < _r0 - 1) || (_s.row > _r1)) {
        continue;
    }
    var _ux = grid_sx(id, _s.col);
    var _uy = grid_sy(id, _s.row);
    if ((_ux + _tp < GRIDC_BF_X1) || (_ux > GRIDC_BF_X2) || (_uy + _tp < GRIDC_BF_Y1) || (_uy > GRIDC_BF_Y2)) {
        continue;
    }
    var _base = (_s.side == 0) ? ((_s.formation >= 0) ? formations[_s.formation].colr : GRIDC_GREEN) : GRIDC_RED;

    // strength shading behind the glyph
    var _frac = clamp(_s.hp_pool / max(1, _s.hp_max), 0, 1);
    draw_set_alpha(0.10 + 0.20 * _frac);
    draw_set_color(_base);
    draw_rectangle(_ux + 1, _uy + 1, _ux + _tp - 1, _uy + _tp - 1, false);
    draw_set_alpha(1);

    grid_draw_unit(_s, _ux + _tp / 2, _uy + _tp / 2, _tp, _base);

    if (_tp >= 22) {
        draw_set_font(fnt_tiny);
        draw_set_color(_base);
        draw_set_halign(fa_right);
        var _cnt_txt = _s.is_vehicle ? $"{round(_frac * 100)}%" : string(_s.men);
        draw_text(_ux + _tp - 3, _uy + _tp - 13, _cnt_txt);
        draw_set_halign(fa_left);
    }

    // sergeant pip
    if ((_s.sgt_hp >= 0) && (_tp >= 22)) {
        var _pc = (_s.sgt_hp == 2) ? GRIDC_GREEN : ((_s.sgt_hp == 1) ? GRIDC_RED : c_black);
        draw_set_color(_pc);
        draw_circle(_ux + 7, _uy + 7, 3, false);
        if (_s.sgt_hp == 0) {
            draw_set_color(GRIDC_RED);
            draw_circle(_ux + 7, _uy + 7, 3, true);
        }
    }

    // selection outline
    if ((_s.side == 0) && (_s.formation >= 0) && grid_sel_has(id, _s.formation)) {
        draw_set_color(c_white);
        draw_rectangle(_ux + 1, _uy + 1, _ux + _tp - 1, _uy + _tp - 1, true);
    }

    if (_s.hit_flash > 0) {
        draw_set_alpha(0.40 * _s.hit_flash / GRIDC_FLASH_FRAMES);
        draw_set_color(GRIDC_RED);
        draw_rectangle(_ux + 2, _uy + 2, _ux + _tp - 2, _uy + _tp - 2, false);
        draw_set_alpha(1);
    }
}

// formation name tags
if (_tp >= 20) {
    draw_set_font(fnt_tiny);
    for (var _fi = 0; _fi < array_length(formations); _fi++) {
        var _f = formations[_fi];
        if (!_f.alive || (array_length(_f.members) <= 0)) {
            continue;
        }
        var _tc = -1;
        var _tr = -1;
        for (var _mi = 0; _mi < array_length(_f.members); _mi++) {
            var _m = squads[_f.members[_mi]];
            if (!_m.alive) {
                continue;
            }
            if ((_tc < 0) || (_m.row < _tr) || ((_m.row == _tr) && (_m.col < _tc))) {
                _tc = _m.col;
                _tr = _m.row;
            }
        }
        if (_tc < 0) {
            continue;
        }
        var _tgx = grid_sx(id, _tc);
        var _tgy = grid_sy(id, _tr) - 13;
        if ((_tgx < GRIDC_BF_X1) || (_tgx > GRIDC_BF_X2 - 20) || (_tgy < GRIDC_BF_Y1) || (_tgy > GRIDC_BF_Y2)) {
            continue;
        }
        draw_set_color(GRIDC_PANEL);
        draw_rectangle(_tgx, _tgy, _tgx + string_width(_f.name) + 6, _tgy + 12, false);
        draw_set_color(_f.colr);
        draw_text(_tgx + 3, _tgy, _f.name);
    }
}

// placement ghost
if (placing) {
    var _pn = array_length(placing_list);
    var _dragging = place_drag && (place_c0 >= 0) && (hover_c >= 0)
        && ((hover_c != place_c0) || (hover_r != place_r0));
    if (_dragging) {
        // Live drag: show the exact tiles the block will stand on and the line
        // the front rank is being drawn along, so the shape is chosen by eye.
        var _dsl = grid_drag_slots(id, place_c0, place_r0, hover_c, hover_r, _pn);
        var _dok = grid_slots_valid(id, placing_list, _dsl);
        for (var _di = 0; _di < array_length(_dsl); _di++) {
            var _dpx = grid_sx(id, _dsl[_di][0]);
            var _dpy = grid_sy(id, _dsl[_di][1]);
            draw_set_alpha(0.25);
            draw_set_color(_dok ? GRIDC_GREEN : GRIDC_RED);
            draw_rectangle(_dpx + 2, _dpy + 2, _dpx + _tp - 2, _dpy + _tp - 2, false);
            draw_set_alpha(1);
            draw_rectangle(_dpx + 2, _dpy + 2, _dpx + _tp - 2, _dpy + _tp - 2, true);
        }
        draw_set_color(_dok ? GRIDC_GREEN : GRIDC_RED);
        draw_line(grid_sx(id, place_c0) + (_tp / 2), grid_sy(id, place_r0) + (_tp / 2),
            grid_sx(id, hover_c) + (_tp / 2), grid_sy(id, hover_r) + (_tp / 2));
    }
    var _fp = grid_footprint(id, _pn);
    var _ok = (hover_c >= 0) && grid_placement_valid(id, placing_list, hover_c, hover_r);
    if (!_dragging && (hover_c >= 0)) {
        var _kk = 0;
        for (var _gy2 = 0; _gy2 < _fp[1]; _gy2++) {
            for (var _gx2 = 0; _gx2 < _fp[0]; _gx2++) {
                if (_kk >= _pn) {
                    break;
                }
                var _bx = grid_sx(id, hover_c + _gx2);
                var _by = grid_sy(id, hover_r + _gy2);
                draw_set_alpha(0.25);
                draw_set_color(_ok ? GRIDC_GREEN : GRIDC_RED);
                draw_rectangle(_bx + 2, _by + 2, _bx + _tp - 2, _by + _tp - 2, false);
                draw_set_alpha(1);
                draw_rectangle(_bx + 2, _by + 2, _bx + _tp - 2, _by + _tp - 2, true);
                _kk += 1;
            }
        }
    }
}

// drag selection box
if (drag_active && (point_distance(drag_x0, drag_y0, _mx, _my) >= GRIDC_DRAG_MIN)) {
    draw_set_color(GRIDC_GREEN);
    draw_set_alpha(0.15);
    draw_rectangle(drag_x0, drag_y0, _mx, _my, false);
    draw_set_alpha(1);
    draw_rectangle(drag_x0, drag_y0, _mx, _my, true);
    // Live count and outline of what the box has caught, so a drag that selects
    // nothing is visibly a drag that selected nothing rather than dead input.
    var _boxf = grid_box_formations(id, drag_x0, drag_y0, _mx, _my);
    for (var _bs = 0; _bs < array_length(squads); _bs++) {
        var _bq = squads[_bs];
        if ((_bq.side != 0) || !_bq.alive || !_bq.deployed) {
            continue;
        }
        if (!array_contains(_boxf, _bq.formation)) {
            continue;
        }
        var _bqx = grid_sx(id, _bq.col);
        var _bqy = grid_sy(id, _bq.row);
        draw_rectangle(_bqx + 1, _bqy + 1, _bqx + _tp - 1, _bqy + _tp - 1, true);
    }
    draw_set_font(fnt_40k_12);
    draw_text(_mx + 10, _my + 10, $"{array_length(_boxf)}");
}

// floating combat text, clipped to the viewport
draw_set_font(fnt_small);
draw_set_halign(fa_center);
// shot marks
for (var _fx = 0; _fx < array_length(shots); _fx++) {
    var _sh = shots[_fx];
    var _prog = 1 - (_sh.life / max(1, _sh.maxlife));
    var _sax = grid_sx(id, _sh.c0) + (_tp / 2);
    var _say = grid_sy(id, _sh.r0) + (_tp / 2);
    var _sbx = grid_sx(id, _sh.c1) + (_tp / 2);
    var _sby = grid_sy(id, _sh.r1) + (_tp / 2);
    draw_set_color(_sh.col);
    if (_sh.kind == GRIDFX_BEAM) {
        draw_set_alpha(0.85 * (1 - _prog));
        draw_line_width(_sax, _say, _sbx, _sby, 2);
    } else if (_sh.kind == GRIDFX_TRACER) {
        draw_set_alpha(0.9);
        var _t0 = max(0, _prog - 0.22);
        draw_line_width(lerp(_sax, _sbx, _t0), lerp(_say, _sby, _t0),
            lerp(_sax, _sbx, _prog), lerp(_say, _sby, _prog), 2);
    } else if (_sh.kind == GRIDFX_MISSILE) {
        if (_prog < 0.6) {
            var _mp = _prog / 0.6;
            draw_set_alpha(0.9);
            draw_circle(lerp(_sax, _sbx, _mp), lerp(_say, _sby, _mp), 3, false);
        } else {
            // The ring is drawn at the blast radius the splash actually used, so
            // what you see is what got hit.
            var _ep = (_prog - 0.6) / 0.4;
            var _rad = (_sh.blast + 0.5) * _tp * _ep;
            draw_set_alpha(0.45 * (1 - _ep));
            draw_circle(_sbx, _sby, _rad, false);
            draw_set_alpha(0.9 * (1 - _ep));
            draw_circle(_sbx, _sby, _rad, true);
        }
    } else if (_sh.kind == GRIDFX_PSY) {
        // Warp discharge. A cast on the spot (ward, perils) is rings only; a
        // bolt crackles across as a jittered double arc, then blooms at the
        // target with a radius that matches the power's real area. Variation
        // comes from the blast size: wide powers get a second trailing ring.
        var _selfcast = ((_sh.c0 == _sh.c1) && (_sh.r0 == _sh.r1));
        if (!_selfcast && (_prog < 0.5)) {
            var _bp = _prog / 0.5;
            var _hx = lerp(_sax, _sbx, _bp);
            var _hy = lerp(_say, _sby, _bp);
            var _jx = irandom_range(-4, 4);
            var _jy = irandom_range(-4, 4);
            draw_set_alpha(0.9);
            draw_line_width(_sax, _say, _hx + _jx, _hy + _jy, 2);
            draw_set_alpha(0.5);
            draw_line_width(_sax, _say, _hx - _jx, _hy - _jy, 1);
        } else {
            var _pp = _selfcast ? _prog : ((_prog - 0.5) / 0.5);
            var _prad = (_sh.blast + 0.5) * _tp * _pp;
            draw_set_alpha(0.40 * (1 - _pp));
            draw_circle(_sbx, _sby, _prad, false);
            draw_set_alpha(0.9 * (1 - _pp));
            draw_circle(_sbx, _sby, _prad, true);
            if (_sh.blast >= 1) {
                draw_set_alpha(0.6 * (1 - _pp));
                draw_circle(_sbx, _sby, _prad * 0.55, true);
            }
        }
    } else {
        draw_set_alpha(0.8 * (1 - _prog));
        var _mx2 = lerp(_sax, _sbx, 0.5);
        var _my2 = lerp(_say, _sby, 0.5);
        draw_line_width(_mx2 - 5, _my2 - 5, _mx2 + 5, _my2 + 5, 2);
        draw_line_width(_mx2 - 5, _my2 + 5, _mx2 + 5, _my2 - 5, 2);
    }
}
draw_set_alpha(1);

for (var _fd = 0; _fd < array_length(floaters); _fd++) {
    var _fe = floaters[_fd];
    var _fx = grid_sx(id, _fe.fc) + _tp / 2 + _fe.fjit;
    var _fy = grid_sy(id, _fe.fr) - 2 - _fe.frise;
    if (!point_in_rectangle(_fx, _fy, GRIDC_BF_X1, GRIDC_BF_Y1, GRIDC_BF_X2, GRIDC_BF_Y2)) {
        continue;
    }
    draw_set_alpha(min(1, _fe.flife / 30));
    draw_set_color(_fe.fcol);
    draw_text(_fx, _fy, _fe.ftxt);
}
draw_set_halign(fa_left);

// order-drag preview: where the selection will stand, and the line being drawn
if (ord_drag && (ord_c0 >= 0) && (hover_c >= 0)
    && ((hover_c != ord_c0) || (hover_r != ord_r0))) {
    var _osn = array_length(grid_selected_squads(id));
    if (_osn > 1) {
        var _opv = grid_drag_slots(id, ord_c0, ord_r0, hover_c, hover_r, _osn, ord_depth);
        draw_set_color(GRIDC_GREEN);
        for (var _oi = 0; _oi < array_length(_opv); _oi++) {
            var _opx = grid_sx(id, _opv[_oi][0]);
            var _opy = grid_sy(id, _opv[_oi][1]);
            draw_set_alpha(0.22);
            draw_rectangle(_opx + 2, _opy + 2, _opx + _tp - 2, _opy + _tp - 2, false);
            draw_set_alpha(0.95);
            draw_rectangle(_opx + 2, _opy + 2, _opx + _tp - 2, _opy + _tp - 2, true);
        }
        draw_line(grid_sx(id, ord_c0) + (_tp / 2), grid_sy(id, ord_r0) + (_tp / 2),
            grid_sx(id, hover_c) + (_tp / 2), grid_sy(id, hover_r) + (_tp / 2));
        draw_set_alpha(1);
        draw_set_font(fnt_40k_12);
        draw_text(grid_sx(id, hover_c) + 12, grid_sy(id, hover_r) + 12,
            $"{_osn} squads, {ord_depth} deep (R)");
    }
}

// hover tooltip: hold still over a tile and it tells you what it is
if ((hover_time >= GRIDC_TIP_DELAY) && (hover_c >= 0) && (phase != GRIDPH_END) && !show_legend) {
    var _tip = "";
    var _lines = [];
    var _occ = grid_squad_at(id, hover_c, hover_r);
    if (_occ >= 0) {
        var _us = squads[_occ];
        _tip = _us.name;
        if (_us.is_vehicle) {
            array_push(_lines, $"{round((_us.hp_pool / max(1, _us.hp_max)) * 100)}% hull, armour {_us.armour}");
            for (var _tl = 0; _tl < array_length(_us.weapons); _tl++) {
                var _twp = _us.weapons[_tl];
                array_push(_lines, $"{_twp.wep}: {_twp.bal} bal, rng {_twp.rng}, AP {_twp.ap_r}, ammo {_twp.ammo}");
            }
        } else {
            array_push(_lines, $"{_us.men} of {_us.men0} standing, armour {_us.armour}, reach {grid_max_range(_us)}");
        }
    } else {
        var _bt2 = blk[hover_c][hover_r];
        if (_bt2 == GRIDT_WALL) {
            _tip = "Wall";
            array_push(_lines, "Impassable. Blocks all fire through it.");
        } else if (_bt2 == GRIDT_BARRIER) {
            _tip = "Window or sandbags";
            array_push(_lines, $"Heavy cover, about {round(GRIDC_BARRIER_SOAK * 100)}%. Impassable, fire passes. Flankable.");
        } else if (_bt2 == GRIDT_LIGHT) {
            _tip = "Trees or rubble";
            array_push(_lines, $"Light cover, about {round(GRIDC_LIGHT_SOAK * 100)}%. Passable. Flankable.");
        } else if (cov[hover_c][hover_r] == 1) {
            _tip = "Trench";
            array_push(_lines, $"About {round((1 - GRIDC_COVER_GOOD) * 100)}% cover from every direction. Cannot be flanked.");
        } else if (cov[hover_c][hover_r] == -1) {
            _tip = "Open ground";
            array_push(_lines, $"Exposed. Takes about {round((GRIDC_COVER_BAD - 1) * 100)}% more fire.");
        } else {
            _tip = "Bare ground";
            array_push(_lines, "No cover either way.");
        }
    }
    var _lh = 16;
    var _tw2 = string_width(_tip) + 20;
    for (var _ml = 0; _ml < array_length(_lines); _ml++) {
        _tw2 = max(_tw2, string_width(_lines[_ml]) + 20);
    }
    var _bh = 8 + (array_length(_lines) * _lh) + 8;
    var _tx2 = min(grid_sx(id, hover_c) + 18, GRIDC_BF_X2 - _tw2 - 4);
    var _ty2 = min(grid_sy(id, hover_r) + 18, GRIDC_BF_Y2 - _bh - 4);
    draw_set_font(fnt_40k_12);
    draw_set_color(c_black);
    draw_set_alpha(0.92);
    draw_rectangle(_tx2, _ty2, _tx2 + _tw2, _ty2 + _bh, false);
    draw_set_alpha(1);
    draw_set_color(GRIDC_GREEN);
    draw_rectangle(_tx2, _ty2, _tx2 + _tw2, _ty2 + _bh, true);
    draw_text(_tx2 + 8, _ty2 + 4, _tip);
    draw_set_color(c_white);
    for (var _dl = 0; _dl < array_length(_lines); _dl++) {
        draw_text(_tx2 + 8, _ty2 + 22 + (_dl * _lh), _lines[_dl]);
    }
}

// legend: every mark on the field and every binding, in two columns so it fits
// inside the battlefield view instead of spilling over the log
if (show_legend) {
    var _lgx = GRIDC_BF_X1 + 16;
    var _lgy = GRIDC_BF_Y1 + 16;
    var _lcol = [
        ["TERRAIN", ""],
        ["Solid grey", "Wall. Impassable, stops shots dead."],
        ["Half grey", "Barrier: window, sandbags, low wall."],
        ["", "Impassable, shots pass, heavy cover."],
        ["Green box", "Trees, scrub, rubble. Walk through, light cover."],
        ["Green ~~", "Trench or crater. Cover from every side."],
        ["Red xx", "Open ground. You take more fire here."],
        ["", ""],
        ["HITS", ""],
        ["MISS", "Grey. The shot went wide."],
        ["DEFLECTED", "Grey. Armour turned it, or a hull took it."],
        ["DODGED", "Yellow. Cover took the shot."],
        ["GRAZED", "Damage landed, nobody died."],
        ["WOUNDED", "Models lost. Red is ours, green theirs."],
        ["", ""],
        ["COVER", ""],
        ["Directional", "Flank a squad and what it hid behind stops"],
        ["", "counting. Trenches cannot be flanked."],
        ["By race", "Tau best, then humans, marines, Orks."],
        ["", "Tyranids barely use it at all."],
    ];
    var _rcol = [
        ["DEPLOYING", ""],
        ["Drag left mouse", "Draw the front rank. The block forms along it."],
        ["Click left mouse", "Drop the block as a rectangle instead."],
        ["R", "Reshape the block: swap frontage for depth."],
        ["Mouse wheel", "Widen or narrow the block."],
        ["Right click", "Take a deployed formation back off the field."],
        ["Escape", "Cancel what you are holding."],
        ["Deploy All", "Lays the army out by your formation settings."],
        ["", ""],
        ["COMMANDING", ""],
        ["Left click", "Select a formation. Drag a box for several."],
        ["Right click", "Move there. On an enemy, focus fire."],
        ["Drag right mouse", "Place the selection in the shape you draw."],
        ["R while dragging", "Set how many ranks deep."],
        ["Alt + left click", "Detach one squad for individual orders."],
        ["X", "Break the selection into single squads."],
        ["Ctrl + 1..9", "Bind a control group. Number alone recalls."],
        ["F1..F6", "Chapter orders: hold, fire line, advance,"],
        ["", "advance and hold, full assault, fall back."],
        ["", ""],
        ["VIEW AND TIME", ""],
        ["WASD or arrows", "Pan the field. Works while deploying."],
        ["Tab", "Toggle the whole-field overview."],
        ["Space", "Pause."],
        ["- and +", "Step the clock down or up."],
        ["Speed button", "Left click faster, right click slower."],
        ["Hover a tile", "Hold still a moment and it tells you what it is."],
        ["Hold Ctrl", "Shade everything the selection can see and reach."],
        ["Click a log line", "Jump the camera to whoever it names."],
        ["Corner pip", "Red: fights hand to hand. Blue: fights at range."],
        ["Ammo", "Squads carry limited volleys. Dry squads charge."],
        ["Auto button", "Your formations fight on their own."],
        ["L", "Close this."],
    ];
    var _lines = max(array_length(_lcol), array_length(_rcol));
    var _lgw = 1020;
    var _lgh = (_lines * 17) + 16;
    draw_set_color(c_black);
    draw_set_alpha(0.90);
    draw_rectangle(_lgx - 10, _lgy - 10, _lgx + _lgw, _lgy + _lgh, false);
    draw_set_alpha(1);
    draw_set_color(GRIDC_GREEN);
    draw_rectangle(_lgx - 10, _lgy - 10, _lgx + _lgw, _lgy + _lgh, true);
    draw_set_font(fnt_40k_12);
    for (var _lg = 0; _lg < _lines; _lg++) {
        var _ly2 = _lgy + (_lg * 17);
        if (_lg < array_length(_lcol)) {
            draw_set_color((_lcol[_lg][1] == "") ? c_white : GRIDC_GREEN);
            draw_text(_lgx, _ly2, _lcol[_lg][0]);
            draw_set_color(c_white);
            draw_text(_lgx + 130, _ly2, _lcol[_lg][1]);
        }
        if (_lg < array_length(_rcol)) {
            draw_set_color((_rcol[_lg][1] == "") ? c_white : GRIDC_GREEN);
            draw_text(_lgx + 500, _ly2, _rcol[_lg][0]);
            draw_set_color(c_white);
            draw_text(_lgx + 640, _ly2, _rcol[_lg][1]);
        }
    }
    draw_set_color(c_white);
}

// hover
if ((hover_c >= 0) && (phase != GRIDPH_END)) {
    draw_set_alpha(0.20);
    draw_set_color(GRIDC_GREEN);
    draw_rectangle(grid_sx(id, hover_c), grid_sy(id, hover_r), grid_sx(id, hover_c) + _tp, grid_sy(id, hover_r) + _tp, false);
    draw_set_alpha(1);
}

// order markers for selected formations
for (var _sf = 0; _sf < array_length(selected); _sf++) {
    var _fo = formations[selected[_sf]];
    if (_fo.order == GRIDORD_MOVE) {
        // One marker per squad, on the tile that squad is actually walking to.
        // A single box on the formation destination told you nothing about where
        // fourteen squads were going to end up.
        draw_set_color(GRIDC_COL_ORDER);
        for (var _om = 0; _om < array_length(_fo.members); _om++) {
            var _os = squads[_fo.members[_om]];
            if (!_os.alive || !_os.deployed) {
                continue;
            }
            var _ot = grid_slot_target(id, _os, _fo);
            var _dx = grid_sx(id, _ot[0]);
            var _dy = grid_sy(id, _ot[1]);
            draw_set_alpha(0.30);
            draw_rectangle(_dx + 3, _dy + 3, _dx + _tp - 3, _dy + _tp - 3, false);
            draw_set_alpha(0.95);
            draw_rectangle(_dx + 3, _dy + 3, _dx + _tp - 3, _dy + _tp - 3, true);
        }
        draw_set_alpha(1);
    }
    if ((_fo.order == GRIDORD_ATTACK) && (_fo.order_target >= 0) && squads[_fo.order_target].alive) {
        var _tg = squads[_fo.order_target];
        draw_set_color(GRIDC_RED);
        var _tx = grid_sx(id, _tg.col);
        var _ty = grid_sy(id, _tg.row);
        draw_rectangle(_tx + 2, _ty + 2, _tx + _tp - 2, _ty + _tp - 2, true);
    }
}


draw_set_alpha(1);
draw_set_halign(fa_left);

// viewport frame drawn last so units never spill over the border
draw_set_color(GRIDC_GREEN);
draw_rectangle(GRIDC_BF_X1, GRIDC_BF_Y1, GRIDC_BF_X2, GRIDC_BF_Y2, true);

// ---------------------------------------------------------------------------
// Left panel: the deployment bar.
// ---------------------------------------------------------------------------
draw_set_color(GRIDC_PANEL);
draw_rectangle(GRIDC_LP_X1, GRIDC_BF_Y1, GRIDC_LP_X2, GRIDC_PANEL_Y2, false);
draw_set_color(GRIDC_GREEN);
draw_rectangle(GRIDC_LP_X1, GRIDC_BF_Y1, GRIDC_LP_X2, GRIDC_PANEL_Y2, true);
draw_set_font(fnt_40k_14);
draw_text(GRIDC_LP_X1 + 10, GRIDC_BF_Y1 + 8, "Available Forces:");
draw_set_font(fnt_40k_12);
draw_set_color(GRIDC_DIM);
draw_text(GRIDC_LP_X1 + 10, GRIDC_BF_Y1 + 40, $"Front holds {combat_width} squads");
draw_text(GRIDC_LP_X1 + 10, GRIDC_BF_Y1 + 62, $"On the line {_online}, reserve {_inres}");
draw_set_color(GRIDC_GREEN);
draw_line(GRIDC_LP_X1 + 8, GRIDC_LIST_Y1 - 12, GRIDC_LP_X2 - 8, GRIDC_LIST_Y1 - 12);

// ---------------------------------------------------------------------------
// Right panel: orders and controls.
// ---------------------------------------------------------------------------
draw_set_color(GRIDC_PANEL);
draw_rectangle(GRIDC_RP_X1, GRIDC_BF_Y1, GRIDC_RP_X2, GRIDC_PANEL_Y2, false);
draw_set_color(GRIDC_GREEN);
draw_rectangle(GRIDC_RP_X1, GRIDC_BF_Y1, GRIDC_RP_X2, GRIDC_PANEL_Y2, true);
draw_set_font(fnt_40k_14);
draw_text(GRIDC_RP_X1 + 10, GRIDC_BF_Y1 + 6, "Orders");
draw_set_font(fnt_40k_12);

var _iy = GRIDC_BF_Y1 + 36;
if (array_length(selected) > 0) {
    var _sel0 = formations[selected[0]];
    var _men = 0;
    var _live = 0;
    for (var _q = 0; _q < array_length(_sel0.members); _q++) {
        var _qs = squads[_sel0.members[_q]];
        if (_qs.alive) {
            _live += 1;
            _men += _qs.men;
        }
    }
    var _ostr = "Advance and engage";
    if (_sel0.order == GRIDORD_HOLD) {
        _ostr = "Holding position";
    } else if (_sel0.order == GRIDORD_MOVE) {
        _ostr = "Repositioning";
    } else if ((_sel0.order == GRIDORD_ATTACK) && (_sel0.order_target >= 0)) {
        _ostr = $"Attacking {squads[_sel0.order_target].name}";
    }
    draw_set_color(GRIDC_GREEN);
    if (array_length(selected) > 1) {
        draw_text(GRIDC_RP_X1 + 10, _iy, $"{array_length(selected)} formations selected");
    } else {
        draw_text(GRIDC_RP_X1 + 10, _iy, $"Formation {_sel0.name}");
    }
    draw_text(GRIDC_RP_X1 + 10, _iy + 22, $"{_live} squads, {_men} models");
    draw_text(GRIDC_RP_X1 + 10, _iy + 44, _ostr);
    var _stt = (_sel0.stance == 1) ? "Charge" : ((_sel0.stance == 2) ? "Avoid melee" : "Auto");
    draw_text(GRIDC_RP_X1 + 10, _iy + 66, $"Stance: {_stt}");

    // Selection detail, in the free space below. Drawn here, inside the right
    // panel chrome, after everything battlefield-side: the first version drew
    // mid-stack, inherited the floaters' centred alignment, and was then painted
    // over by this very panel's background, leaving clipped fragments.
    draw_set_halign(fa_left);
    var _isq = grid_selected_squads(id);
    var _py2 = _iy + 100;
    if (array_length(_isq) == 1) {
        // One squad: the full card. Name first, since that is what was missing.
        var _one = squads[_isq[0]];
        draw_set_color(c_white);
        draw_set_font(fnt_40k_14);
        draw_text(GRIDC_RP_X1 + 10, _py2, _one.name);
        draw_set_font(fnt_40k_12);
        draw_set_color(GRIDC_GREEN);
        _py2 += 24;
        draw_text(GRIDC_RP_X1 + 10, _py2, grid_unit_def(_one.type).disp);
        _py2 += 20;
        if (_one.is_vehicle) {
            draw_text(GRIDC_RP_X1 + 10, _py2, $"Hull {round(_one.hp_pool)} of {round(_one.hp_max)}");
        } else {
            draw_text(GRIDC_RP_X1 + 10, _py2, $"{_one.men} of {_one.men0} men, {_one.hp_man} hp each");
        }
        _py2 += 20;
        draw_text(GRIDC_RP_X1 + 10, _py2, $"Armour {_one.armour}");
        _py2 += 20;
        draw_text(GRIDC_RP_X1 + 10, _py2, $"Melee {_one.mel}  Ranged {_one.bal}");
        _py2 += 20;
        if (array_length(_one.weapons) > 1) {
            for (var _wi = 0; _wi < array_length(_one.weapons); _wi++) {
                var _w = _one.weapons[_wi];
                draw_set_color(c_white);
                draw_text(GRIDC_RP_X1 + 10, _py2, _w.wep);
                _py2 += 16;
                draw_set_color(GRIDC_GREEN);
                draw_text(GRIDC_RP_X1 + 26, _py2, $"Ballistic {_w.bal}  Range {_w.rng}  AP {_w.ap_r}");
                _py2 += 14;
                draw_text(GRIDC_RP_X1 + 26, _py2, $"Ammo {_w.ammo}{(_w.fire_int > 1) ? $"  Fires every {_w.fire_int} ticks" : ""}");
                _py2 += 18;
            }
        } else {
            var _w0 = _one.weapons[0];
            if (_one.geared) {
                var _apx = "";
                if ((_w0.ap_r > 0) || (_one.ap_m > 0)) {
                    _apx = $"  AP {max(_w0.ap_r, _one.ap_m)}";
                }
                var _mob2 = "";
                if (_one.can_jump && (_one.type != "assault") && (_one.type != "assault_term")) {
                    _mob2 = "  Jump Packs";
                } else if (_one.spd > grid_unit_def(_one.type).spd) {
                    _mob2 = "  Bikes";
                }
                draw_text(GRIDC_RP_X1 + 10, _py2, $"{_w0.wep}{_apx}{_mob2}");
                _py2 += 20;
            }
            draw_text(GRIDC_RP_X1 + 10, _py2, $"Range {_w0.rng} tiles  Speed {_one.spd}");
            _py2 += 20;
            if (_w0.fire_int > 1) {
                draw_text(GRIDC_RP_X1 + 10, _py2, $"Fires every {_w0.fire_int} ticks");
                _py2 += 20;
            }
            if (_w0.ammo <= 0) {
                draw_set_color(GRIDC_ORANGE);
                draw_text(GRIDC_RP_X1 + 10, _py2, "OUT OF AMMO");
                draw_set_color(GRIDC_GREEN);
            } else {
                draw_text(GRIDC_RP_X1 + 10, _py2, $"Ammo: {_w0.ammo} volleys");
            }
            _py2 += 20;
        }
        // The armoury line: what the squad actually carries, and how well it
        // bites through plate. Only shown when the numbers came from real gear.
        if (_one.geared) {
            var _apx = "";
            if ((_one.ap_r > 0) || (_one.ap_m > 0)) {
                _apx = $"  AP {max(_one.ap_r, _one.ap_m)}";
            }
            var _mob2 = "";
            if (_one.can_jump && (_one.type != "assault") && (_one.type != "assault_term")) {
                _mob2 = "  Jump Packs";
            } else if (_one.spd > grid_unit_def(_one.type).spd) {
                _mob2 = "  Bikes";
            }
            draw_text(GRIDC_RP_X1 + 10, _py2, $"{_one.wep}{_apx}{_mob2}");
            _py2 += 20;
        }
        draw_text(GRIDC_RP_X1 + 10, _py2, $"Range {_one.rng} tiles  Speed {_one.spd}");
        _py2 += 20;
        if (_one.fire_int > 1) {
            draw_text(GRIDC_RP_X1 + 10, _py2, $"Fires every {_one.fire_int} ticks");
            _py2 += 20;
        }
        if (_one.ammo <= 0) {
            draw_set_color(GRIDC_ORANGE);
            draw_text(GRIDC_RP_X1 + 10, _py2, "OUT OF AMMO");
            draw_set_color(GRIDC_GREEN);
        } else {
            draw_text(GRIDC_RP_X1 + 10, _py2, $"Ammo: {_one.ammo} volleys");
        }
        _py2 += 20;
        if (_one.sgt_hp == 0) {
            draw_set_color(GRIDC_RED);
            draw_text(GRIDC_RP_X1 + 10, _py2, "Sergeant down");
            _py2 += 20;
        }
    } else if (array_length(_isq) > 1) {
        // Mixed selection: one block per type, separated as asked, each with its
        // pooled health, worst armour, damage, range and speed.
        var _types = [];
        var _agg = {};
        for (var _ii = 0; _ii < array_length(_isq); _ii++) {
            var _is = squads[_isq[_ii]];
            var _k2 = _is.type;
            if (!variable_struct_exists(_agg, _k2)) {
                _agg[$ _k2] = {
                    disp: grid_unit_def(_k2).disp, n: 0, veh: _is.is_vehicle,
                    hp: 0, hp0: 0, men: 0, men0: 0, arm: 999, amo: 99999,
                    mel: _is.mel, bal: _is.bal, rng: _is.rng, spd: _is.spd,
                    mounts: 0,
                };
                array_push(_types, _k2);
            }
            var _a2 = _agg[$ _k2];
            _a2.n += 1;
            _a2.mounts = max(_a2.mounts, array_length(_is.weapons));
            _a2.arm = min(_a2.arm, _is.armour);
            _a2.amo = min(_a2.amo, _is.ammo);
            if (_is.is_vehicle) {
                _a2.hp += _is.hp_pool;
                _a2.hp0 += _is.hp_max;
            } else {
                _a2.hp += _is.men * _is.hp_man;
                _a2.hp0 += _is.men0 * _is.hp_man;
                _a2.men += _is.men;
                _a2.men0 += _is.men0;
            }
        }
        draw_set_color(GRIDC_GREEN);
        draw_text(GRIDC_RP_X1 + 10, _py2, $"Selected: {array_length(_isq)} squads");
        _py2 += 22;
        for (var _ti2 = 0; (_ti2 < array_length(_types)) && (_py2 < 480); _ti2++) {
            var _g2 = _agg[$ _types[_ti2]];
            draw_set_color(c_white);
            draw_text(GRIDC_RP_X1 + 10, _py2, $"{_g2.n}x {_g2.disp}");
            draw_set_color(GRIDC_GREEN);
            if (_g2.veh) {
                draw_text(GRIDC_RP_X1 + 10, _py2 + 16, $"  Hull {round(_g2.hp)}/{round(_g2.hp0)}  Armour {_g2.arm}  Mounts {_g2.mounts}");
            } else {
                draw_text(GRIDC_RP_X1 + 10, _py2 + 16, $"  {_g2.men}/{_g2.men0} men  HP {round(_g2.hp)}/{round(_g2.hp0)}  Arm {_g2.arm}");
            }
            draw_text(GRIDC_RP_X1 + 10, _py2 + 32, $"  Mel {_g2.mel}  Rng dmg {_g2.bal}  Reach {_g2.rng}  Spd {_g2.spd}  Ammo {_g2.amo}");
            _py2 += 54;
        }
    }
} else {
    draw_set_color(GRIDC_DIM);
    if (phase == GRIDPH_DEPLOY) {
        draw_text(GRIDC_RP_X1 + 10, _iy, "Pick a type on the left.");
        draw_text(GRIDC_RP_X1 + 10, _iy + 22, "Wheel reshapes a block.");
        draw_text(GRIDC_RP_X1 + 10, _iy + 44, "R rotates it.");
        draw_text(GRIDC_RP_X1 + 10, _iy + 66, "Terminators drop anywhere.");
        draw_text(GRIDC_RP_X1 + 10, _iy + 88, "Right click a squad: recall.");
    } else {
        draw_text(GRIDC_RP_X1 + 10, _iy, "Left click: select.");
        draw_text(GRIDC_RP_X1 + 10, _iy + 22, "Left drag: box select.");
        draw_text(GRIDC_RP_X1 + 10, _iy + 44, "Right click ground: move.");
        draw_text(GRIDC_RP_X1 + 10, _iy + 66, "Right click foe: focus fire.");
        draw_text(GRIDC_RP_X1 + 10, _iy + 88, "Assaults leap on focus fire.");
    }
    draw_text(GRIDC_RP_X1 + 10, _iy + 110, "WASD pans, Tab zooms.");
}

// ---------------------------------------------------------------------------
// Bottom log: the full feed, vanilla combat readout style.
// ---------------------------------------------------------------------------
draw_set_color(GRIDC_PANEL);
draw_rectangle(GRIDC_BF_X1, GRIDC_LOG_Y1, GRIDC_BF_X2, GRIDC_LOG_Y2, false);
draw_set_color(GRIDC_GREEN);
draw_rectangle(GRIDC_BF_X1, GRIDC_LOG_Y1, GRIDC_BF_X2, GRIDC_LOG_Y2, true);
// draw() drains the pending queue itself and restores the draw state after, so
// the first line lands on GRIDC_LOG_Y1 + 8 exactly where the old feed drew it.
log.draw(GRIDC_BF_X1 + 4, GRIDC_LOG_Y1);

// ---------------------------------------------------------------------------
// Buttons, drawn from the same table the Step event hit tests.
// ---------------------------------------------------------------------------
draw_set_font(fnt_40k_12);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _btns = grid_buttons(id);
for (var _bi = 0; _bi < array_length(_btns); _bi++) {
    var _bt = _btns[_bi];
    var _hov = _bt.benabled && point_in_rectangle(_mx, _my, _bt.bx, _bt.by, _bt.bx + _bt.bw, _bt.by + _bt.bh);
    if (_hov) {
        draw_set_alpha(0.18);
        draw_set_color(GRIDC_GREEN);
        draw_rectangle(_bt.bx, _bt.by, _bt.bx + _bt.bw, _bt.by + _bt.bh, false);
        draw_set_alpha(1);
    }
    draw_set_color(_bt.benabled ? GRIDC_GREEN : GRIDC_DIM);
    draw_rectangle(_bt.bx, _bt.by, _bt.bx + _bt.bw, _bt.by + _bt.bh, true);
    draw_text(_bt.bx + _bt.bw / 2, _bt.by + _bt.bh / 2, _bt.blabel);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// ---------------------------------------------------------------------------
// Deployment popup.
// ---------------------------------------------------------------------------
if (popup_open) {
    var _pr = grid_popup_rect();
    var _px = _pr[0];
    var _py = _pr[1];
    var _pw = _pr[2] - _pr[0];
    var _ph = _pr[3] - _pr[1];
    draw_set_color(GRIDC_PANEL);
    draw_rectangle(_px, _py, _px + _pw, _py + _ph, false);
    draw_set_color(GRIDC_GREEN);
    draw_rectangle(_px, _py, _px + _pw, _py + _ph, true);
    var _pd = grid_unit_def(popup_type);
    var _pool = grid_pool_indices(id, popup_type);
    draw_set_font(fnt_40k_14);
    draw_text(_px + 12, _py + 10, $"{_pd.disp}: choose members ({array_length(_pool)} available)");
    draw_set_font(fnt_tiny);
    draw_set_color(GRIDC_DIM);
    draw_text(_px + 12, _py + 34, "Wheel scrolls. Right click or click outside to cancel.");

    draw_set_font(fnt_40k_12);
    for (var _i = 0; _i < 8; _i++) {
        var _idx = popup_scroll + _i;
        if (_idx >= array_length(_pool)) {
            break;
        }
        var _sq = squads[_pool[_idx]];
        var _ry = _py + 52 + _i * 56;
        if (_sq.picked) {
            draw_set_alpha(0.12);
            draw_set_color(GRIDC_GREEN);
            draw_rectangle(_px + 8, _ry, _px + _pw - 8, _ry + 52, false);
            draw_set_alpha(1);
        }
        draw_set_color(_sq.picked ? GRIDC_GREEN : GRIDC_DIM);
        draw_rectangle(_px + 8, _ry, _px + _pw - 8, _ry + 52, true);
        draw_rectangle(_px + 18, _ry + 18, _px + 34, _ry + 34, true);
        if (_sq.picked) {
            draw_line(_px + 20, _ry + 26, _px + 26, _ry + 32);
            draw_line(_px + 26, _ry + 32, _px + 32, _ry + 20);
        }
        draw_set_color(GRIDC_GREEN);
        draw_text(_px + 46, _ry + 6, _sq.name);
        draw_set_font(fnt_tiny);
        draw_set_color(GRIDC_DIM);
        var _hp = _sq.hp_pool;
        var _ar = _sq.armour;
        var _ml = _sq.mel;
        var _bl = _sq.bal;
        var _mv = _sq.spd;
        draw_text(_px + 46, _ry + 30, $"HP {_hp}   Armour {_ar}   Melee {_ml}   Ballistic {_bl}   Speed {_mv}");
        draw_set_font(fnt_40k_12);
        draw_set_color(GRIDC_GREEN);

    }

    var _ps = grid_picked_stats(id);
    var _pn2 = _ps.n;

    var _pp2 = _ps.pow;
    var _pm2 = _ps.mv;
    draw_set_font(fnt_40k_12);
    draw_set_color(GRIDC_GREEN);
    draw_text(_px + 14, _py + _ph - 44, $"Formation: {_pn2} squads   Power {_pp2}   Speed {_pm2}");
    draw_set_color((_pn2 > 0) ? GRIDC_GREEN : GRIDC_DIM);
    draw_rectangle(_px + _pw - 190, _py + _ph - 58, _px + _pw - 14, _py + _ph - 12, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_px + _pw - 102, _py + _ph - 35, "Deploy");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ---------------------------------------------------------------------------
// End screen.
// ---------------------------------------------------------------------------
if (phase == GRIDPH_END) {
    draw_set_alpha(0.72);
    draw_set_color(c_black);
    draw_rectangle(0, 0, 1600, 900, false);
    draw_set_alpha(1);
    draw_set_color(GRIDC_PANEL);
    draw_rectangle(560, 300, 1040, 640, false);
    draw_set_color(GRIDC_GREEN);
    draw_rectangle(560, 300, 1040, 640, true);
    draw_set_font(fnt_40k_30b);
    draw_set_halign(fa_center);
    draw_set_color((result > 0) ? GRIDC_GREEN : GRIDC_RED);
    draw_text(800, 330, (result > 0) ? "VICTORY" : "DEFEAT");
    draw_set_font(fnt_40k_12);
    draw_set_color(GRIDC_GREEN);
    draw_text(800, 400, $"Enemy slain: {total_ekills}");
    draw_text(800, 424, $"Battle brothers lost: {total_pkills}");
    draw_text(800, 448, $"Mobs wiped out: {wiped_e}");
    draw_text(800, 472, $"Squads lost: {wiped_p}");
    draw_text(800, 496, $"Duration: {ticks} ticks");
    draw_rectangle(660, 560, 940, 616, true);
    draw_set_valign(fa_middle);
    draw_text(800, 588, pending_live ? "After Action Report" : "Return to Map");
    draw_set_valign(fa_top);
    draw_set_halign(fa_left);
}

// Reset draw state for the cursor, which draws on top of this overlay.
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(fnt_small);
if (!instance_exists(obj_cursor)) {
    draw_sprite(spr_cursor, 0, _mx, _my);
}
