using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.Graphics as Gfx;

// Main application class
class EMOMApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [new EMOMConfigView(), new EMOMConfigDelegate()];
    }
}

// Configuration view
class EMOMConfigView extends Ui.View {
    private var _rounds;
    private var _workTime;
    private var _selection;

    function initialize() {
        View.initialize();
        _rounds = 10;
        _workTime = 60;
        _selection = 0; // 0 = rounds, 1 = work time, 2 = start
    }

    function onLayout(dc) {
    }

    function onShow() {
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // Title
        dc.drawText(centerX, 10, Gfx.FONT_SMALL, "EMOM TIMER", Gfx.TEXT_JUSTIFY_CENTER);

        // Rounds
        var roundsColor = (_selection == 0) ? Gfx.COLOR_YELLOW : Gfx.COLOR_WHITE;
        dc.setColor(roundsColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, 50, Gfx.FONT_MEDIUM, "Rounds: " + _rounds, Gfx.TEXT_JUSTIFY_CENTER);

        // Work Time
        var timeColor = (_selection == 1) ? Gfx.COLOR_YELLOW : Gfx.COLOR_WHITE;
        dc.setColor(timeColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, 90, Gfx.FONT_MEDIUM, "Time: " + _workTime + "s", Gfx.TEXT_JUSTIFY_CENTER);

        // Start button
        var startColor = (_selection == 2) ? Gfx.COLOR_GREEN : Gfx.COLOR_WHITE;
        dc.setColor(startColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, 130, Gfx.FONT_MEDIUM, "START", Gfx.TEXT_JUSTIFY_CENTER);

        // Instructions
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 30, Gfx.FONT_TINY, "UP/DOWN SELECT", Gfx.TEXT_JUSTIFY_CENTER);
    }

    function onHide() {
    }

    function moveSelectionUp() {
        _selection = (_selection - 1 + 3) % 3;
        Ui.requestUpdate();
    }

    function moveSelectionDown() {
        _selection = (_selection + 1) % 3;
        Ui.requestUpdate();
    }

    function increaseValue() {
        if (_selection == 0) {
            _rounds = (_rounds < 60) ? _rounds + 1 : 60;
        } else if (_selection == 1) {
            _workTime = (_workTime < 300) ? _workTime + 5 : 300;
        }
        Ui.requestUpdate();
    }

    function decreaseValue() {
        if (_selection == 0) {
            _rounds = (_rounds > 1) ? _rounds - 1 : 1;
        } else if (_selection == 1) {
            _workTime = (_workTime > 10) ? _workTime - 5 : 10;
        }
        Ui.requestUpdate();
    }

    function startTimer() {
        if (_selection == 2) {
            Ui.pushView(new EMOMTimerView(_rounds, _workTime), new EMOMTimerDelegate(), Ui.SLIDE_LEFT);
        }
    }

    function getRounds() {
        return _rounds;
    }

    function getWorkTime() {
        return _workTime;
    }

    function getSelection() {
        return _selection;
    }
}

// Configuration input delegate
class EMOMConfigDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onNextPage() {
        var view = Ui.View.findViewById("config");
        if (view == null) {
            view = Ui.getCurrentView()[0];
        }
        view.moveSelectionDown();
        return true;
    }

    function onPreviousPage() {
        var view = Ui.View.findViewById("config");
        if (view == null) {
            view = Ui.getCurrentView()[0];
        }
        view.moveSelectionUp();
        return true;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        var view = Ui.getCurrentView()[0];
        
        if (key == Ui.KEY_UP) {
            view.decreaseValue();
            return true;
        } else if (key == Ui.KEY_DOWN) {
            view.increaseValue();
            return true;
        } else if (key == Ui.KEY_ENTER) {
            view.startTimer();
            return true;
        }
        return false;
    }

    function onSelect() {
        var view = Ui.getCurrentView()[0];
        view.startTimer();
        return true;
    }
}

// Timer view
class EMOMTimerView extends Ui.View {
    private var _totalRounds;
    private var _currentRound;
    private var _workTime;
    private var _timeRemaining;
    private var _timer;
    private var _isRunning;

    function initialize(rounds, workTime) {
        View.initialize();
        _totalRounds = rounds;
        _currentRound = 1;
        _workTime = workTime;
        _timeRemaining = workTime;
        _isRunning = true;
        
        _timer = new Timer.Timer();
        _timer.start(method(:timerCallback), 1000, true);
    }

    function timerCallback() {
        if (_isRunning) {
            _timeRemaining--;
            
            if (_timeRemaining <= 0) {
                // Vibrate at end of round
                vibrateAlert();
                
                _currentRound++;
                if (_currentRound > _totalRounds) {
                    _isRunning = false;
                    _timer.stop();
                } else {
                    _timeRemaining = _workTime;
                }
            }
            Ui.requestUpdate();
        }
    }

    function vibrateAlert() {
        if (Attention has :vibrate) {
            var vibeData = [new Attention.VibeProfile(50, 200)];
            Attention.vibrate(vibeData);
        }
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        if (!_isRunning) {
            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 20, Gfx.FONT_LARGE, "COMPLETE!", Gfx.TEXT_JUSTIFY_CENTER);
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY + 30, Gfx.FONT_SMALL, "Press BACK", Gfx.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Round indicator
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, 20, Gfx.FONT_SMALL, "Round " + _currentRound + "/" + _totalRounds, Gfx.TEXT_JUSTIFY_CENTER);

        // Time remaining
        var timeColor = (_timeRemaining <= 5) ? Gfx.COLOR_RED : Gfx.COLOR_GREEN;
        dc.setColor(timeColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 30, Gfx.FONT_NUMBER_HOT, _timeRemaining.format("%d"), Gfx.TEXT_JUSTIFY_CENTER);

        // Seconds label
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY + 20, Gfx.FONT_SMALL, "seconds", Gfx.TEXT_JUSTIFY_CENTER);

        // Pause/Resume hint
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 30, Gfx.FONT_TINY, "SELECT: PAUSE", Gfx.TEXT_JUSTIFY_CENTER);
    }

    function togglePause() {
        _isRunning = !_isRunning;
        Ui.requestUpdate();
    }

    function stopTimer() {
        if (_timer != null) {
            _timer.stop();
        }
    }

    function onHide() {
        stopTimer();
    }
}

// Timer input delegate
class EMOMTimerDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        var view = Ui.getCurrentView()[0];
        view.togglePause();
        return true;
    }

    function onBack() {
        var view = Ui.getCurrentView()[0];
        view.stopTimer();
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }
}

function getApp() {
    return App.getApp();
}