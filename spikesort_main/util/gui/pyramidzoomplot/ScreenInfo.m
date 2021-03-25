%%@ NOTE FIXME - MAY NEED TO GET MAX. Test for multiple monitors

function MonitorPositions = ScreenInfo
    ScreenPixelsPerInch = java.awt.Toolkit.getDefaultToolkit().getScreenResolution();
    ScreenDevices = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices();
%%@ FIXME
%%@ This no longer works on Mac R2019, so as a fallback, just assume we're
%%@ on screen #1. This may cause problems for multiple monitors, but is
%%@ probably alright for now
    MainScreen = 1;
    MainBounds = ScreenDevices(MainScreen).getDefaultConfiguration().getBounds();
    MonitorPositions = zeros(numel(ScreenDevices),4);
    for n = 1:numel(ScreenDevices)
        Bounds = ScreenDevices(n).getDefaultConfiguration().getBounds();
        MonitorPositions(n,:) = [Bounds.getLocation().getX() + 1,-Bounds.getLocation().getY() + 1 - Bounds.getHeight() + MainBounds.getHeight(),Bounds.getWidth(),Bounds.getHeight()];
    end
end
