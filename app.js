let express = require('express');
let path = require('path');

let fs = require("fs");
let demofile = require("demofile");

let summary;

parseDemoFile("test.dem")

let app = express();
// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/demo/:id',function(req, res, next) {
  res.json(summary.snapshots[req.params.id]);
});

app.get('/demo',function(req, res, next) {
  res.json(summary);
});


// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

let counter = 0;

module.exports = app;

function parseDemoFile(path) {
  fs.readFile(path, (err, buffer) => {
    let demo = new demofile.DemoFile();

    demo.on("start", () => {
      summary = new Demo(demo);
    });

    demo.on("tickstart", e => {
      summary.snapshots[e+1] = new DemoSnapshot(demo);
      counter += 1;
    });

    demo.on("tickend", e => {
      summary.snapshots[e] = new DemoSnapshot(demo);
      counter += 1;
    });

    demo.parse(buffer);
  });
}


class Demo {
  constructor(demo) {
    this.tickrate = demo.tickRate;
    this.totalTicks = demo.header.playbackTicks;
    this.map = demo.mapName;
    this.snapshots = {};
  }

  toJSON() {
    return {
      "Tickrate" : this.tickrate,
      "TotalTicks" : this.totalTicks,
      "Map" : this.map
    };
  };
}

class DemoSnapshot {
  constructor(demo) {
    this.currentTime = demo.currentTime;
    this.teams = []
    if(demo.teams.length > 0) {
      let ct = new Team(demo.teams[3]);
      let t = new Team(demo.teams[2]);
      this.teams.push(ct);
      this.teams.push(t);
    }
  }
}

class Team {
  constructor(team) {
    this.name = team.teamName;
    this.score = team.score;
    this.players = []
    if(team.members.length > 0) {
      team.members.forEach(p => this.players.push(new Player(p)));
    }
  }
}

class Player {
  constructor(player) {
    this.name = player.name;
    this.kills = player.kills;
    this.deaths = player.deaths;
    this.assists = player.assists;
    this.mvps = player.mvps;
    this.position = player.position;
    this.vel = player.velocity;
    this.lifeState = player.lifeState;
    this.isScoped = player.isScoped;
    this.isWalking = player.isWalking;
    this.isDucking = player.isDucking;
    this.isDucked = player.isDucked;
    this.fFlags = player.getProp("DT_BasePlayer","m_fFlags");
    this.weapons = player.weapons.map((obj) => {
      return obj.itemName;
    });
    this.currWeapon = new Weapon(player.weapon);
    this.hasDefuser = player.hasDefuser;
    this.hasHelmet = player.hasHelmet;
    this.hasC4 = player.hasC4;
    this.armor = player.armor;
    this.health = player.health;
    this.money = player.account;
    this.view = player.eyeAngles;
    this.isDefusing = player.isDefusing;
  }
}

class Weapon {
  constructor(weapon) {
    if (weapon == null) {
      this.currWeapon = ""
      this.ammo = 0;
    }
    else {
      this.currWeapon = weapon.itemName;
      if(weapon.props.hasOwnProperty("DT_BaseCSGrenade")){
        this.isGrenade = true;
        this.throwStrength = weapon.getProp("DT_BaseCSGrenade","m_flThrowStrength");
        this.pinPulled = weapon.getProp("DT_BaseCSGrenade","m_bPinPulled");
        this.throwTime = weapon.getProp("DT_BaseCSGrenade","m_fThrowTime");
      } else {
        this.isGrenade = false;
        this.clipAmmo = weapon.clipAmmo;
        this.ammo = weapon.reserveAmmo;
        this.burst = weapon.getProp("DT_WeaponCSBase","m_bBurstMode");
        this.silencer = weapon.getProp("DT_WeaponCSBase","m_bSilencerOn");
      }
    }
  }
}