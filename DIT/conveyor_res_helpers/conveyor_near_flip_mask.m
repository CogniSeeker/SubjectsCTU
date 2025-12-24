function nearFlip = conveyor_near_flip_mask(win_centers, t_flip, revBlank)
%CONVEYOR_NEAR_FLIP_MASK Mark windows too close to direction flips.

nearFlip = false(size(win_centers));
for k = 1:numel(t_flip)
    nearFlip = nearFlip | (abs(win_centers - t_flip(k)) <= revBlank);
end
end
