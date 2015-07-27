path2curve = R._path2curve = cacher(function(path, path2) {
            var pth = !path2 && paths(path);
            if (!path2 && pth.curve) {
                return pathClone(pth.curve);
            }
            var p = pathToAbsolute(path),                
                p2 = path2 && pathToAbsolute(path2),
                attrs = {
                    x: 0,
                    y: 0,
                    bx: 0,
                    by: 0,
                    X: 0,
                    Y: 0,
                    qx: null,
                    qy: null
                },
                attrs2 = {
                    x: 0,
                    y: 0,
                    bx: 0,
                    by: 0,
                    X: 0,
                    Y: 0,
                    qx: null,
                    qy: null
                },
                processPath = function(path, d, pcom) {
                    var nx, ny;
                    if (!path) {
                        return ["C", d.x, d.y, d.x, d.y, d.x, d.y];
                    }!(path[0] in {
                        T: 1,
                        Q: 1
                    }) && (d.qx = d.qy = null);
                   
                   switch (path[0]) {
                    case "M":
                        d.X = path[1];
                        d.Y = path[2];
                        break;
                    case "A":
                        path = ["C"][concat](a2c[apply](0, [d.x, d.y][concat](path.slice(1))));
                        break;
                    case "S":
                        if (pcom == "C" || pcom == "S") { // In S we have to take into account, if the previous command is C/S 
                          nx = d.x * 2 - d.bx;
                          ny = d.y * 2 - d.by; 
                        }
                       else { // or some else command
                          nx = d.x;
                          ny = d.y;
                        }
                        path = ["C", nx, ny][concat](path.slice(1));
                        break;
                    case "T":
                        if (pcom == "Q" || pcom == "T") { // In T we have to take into account, if the previous command is Q/T
                          d.qx = d.x * 2 - d.qx;
                          d.qy = d.y * 2 - d.qy;
                        }
                        else {
                          d.qx = d.x;
                          d.qy = d.y;
                        }
                        path = ["C"][concat](q2c(d.x, d.y, d.qx, d.qy, path[1], path[2]));
                        break;
                    case "Q":
                        d.qx = path[1];
                        d.qy = path[2];
                        path = ["C"][concat](q2c(d.x, d.y, path[1], path[2], path[3], path[4]));
                        break;
                    case "L":
                        path = ["C"][concat](l2c(d.x, d.y, path[1], path[2]));
                        break;
                    case "H":
                        path = ["C"][concat](l2c(d.x, d.y, path[1], d.y));
                        break;
                    case "V":
                        path = ["C"][concat](l2c(d.x, d.y, d.x, path[1]));
                        break;
                    case "Z":
                        path = ["C"][concat](l2c(d.x, d.y, d.X, d.Y));
                        break;
                    }
                    return path;
                },
                fixArc = function(pp, i) {
                    if (pp[i].length > 7) {
                        pp[i].shift();
                        var pi = pp[i];
                        while (pi.length) {
                          pcoms1[i]="A"; // if created multiple C:s, their original seg is saved
                          p2 && (pcoms2[i]="A"); // the same as above
                          pp.splice(i++, 0, ["C"][concat](pi.splice(0, 6)));
                        }
                        pp.splice(i, 1);
                        ii = mmax(p.length, p2 && p2.length || 0);
                    }
                },
                fixM = function(path1, path2, a1, a2, i) {
                    if (path1 && path2 && path1[i][0] == "M" && path2[i][0] != "M") {
                        path2.splice(i, 0, ["M", a2.x, a2.y]);
                        a1.bx = 0;
                        a1.by = 0;
                        a1.x = path1[i][1];
                        a1.y = path1[i][2];
                        ii = mmax(p.length, p2 && p2.length || 0);
                    }
                }, 
                pcoms1 = [], // path commands of original path p
                pcoms2 = [], // path commands of original path p2
                pfirst = "", // temporary holder for original path command
                pcom = ""; // holder for previous path command of original path
            for (var i = 0, ii = mmax(p.length, p2 && p2.length || 0); i < ii; i++) {
              p[i] && (pfirst = p[i][0]); // save current path command

              if (pfirst != "C") // C is not saved yet, because it may be result of conversion
              {
                pcoms1[i] = pfirst; // Save current path command
                i && ( pcom = pcoms1[i-1]); // Get previous path command pcom
              }
              p[i] = processPath(p[i], attrs, pcom); // Previous path command is inputted to processPath

              if (pcoms1[i] != "A" && pfirst == "C") pcoms1[i] = "C"; // A is the only command
              // which may produce multiple C:s
              // so we have to make sure that C is also C in original path
              
              fixArc(p, i); // fixArc adds also the right amount of A:s to pcoms1
              
              if (p2) { // the same procedures is done to p2
                p2[i] && (pfirst = p2[i][0]);
                if (pfirst != "C")
                {
                  pcoms2[i] = pfirst;
                  i && (pcom = pcoms2[i-1]);
                }              
                p2[i] = processPath(p2[i], attrs2, pcom);

                if (pcoms2[i]!="A" && pfirst=="C") pcoms2[i]="C";
              
                fixArc(p2, i);
              }
                fixM(p, p2, attrs, attrs2, i);
                fixM(p2, p, attrs2, attrs, i);
                var seg = p[i],
                    seg2 = p2 && p2[i],
                    seglen = seg.length,
                    seg2len = p2 && seg2.length;
                attrs.x = seg[seglen - 2];
                attrs.y = seg[seglen - 1];
                attrs.bx = toFloat(seg[seglen - 4]) || attrs.x;
                attrs.by = toFloat(seg[seglen - 3]) || attrs.y;
                attrs2.bx = p2 && (toFloat(seg2[seg2len - 4]) || attrs2.x);
                attrs2.by = p2 && (toFloat(seg2[seg2len - 3]) || attrs2.y);
                attrs2.x = p2 && seg2[seg2len - 2];
                attrs2.y = p2 && seg2[seg2len - 1];
                
                console_log("PCOMS1:"+pcoms1.toString());
                console_log("PCOMS2:"+pcoms2.toString());
            }

            if (!p2) {
                pth.curve = pathClone(p);
            }
            return p2 ? [p, p2] : p;
        }, null, pathClone)