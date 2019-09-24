%%@ NOTE FIXME - MAY NEED TO GET MAX. Test for multiple monitors

function MonitorPositions = ScreenInfo
    ScreenPixelsPerInch = java.awt.Toolkit.getDefaultToolkit().getScreenResolution();
    ScreenDevices = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices();
    MainScreen = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getScreen()+1;
    MainBounds = ScreenDevices(MainScreen).getDefaultConfiguration().getBounds();
    MonitorPositions = zeros(numel(ScreenDevices),4);
    for n = 1:numel(ScreenDevices)
        Bounds = ScreenDevices(n).getDefaultConfiguration().getBounds();
        MonitorPositions(n,:) = [Bounds.getLocation().getX() + 1,-Bounds.getLocation().getY() + 1 - Bounds.getHeight() + MainBounds.getHeight(),Bounds.getWidth(),Bounds.getHeight()];
    end
end
