fig = figure();
ax = axes(fig);
h=text(1,1,'location');
fig.WindowButtonMotionFcn = {@mouseMotionCB, ax};
function mouseMotionCB(fig, event, ax_handle,h)
num2str(ax_handle.CurrentPoint(1,1:2))
    title(ax_handle,['X = ' num2str(ax_handle.CurrentPoint(1,1:1))]);
    %fprintf('Current Point is %f %f %f\n', ax_handle.CurrentPoint(1,1:3));
end