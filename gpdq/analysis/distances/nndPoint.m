function dist = nndPoint(point, neighbours)
    if size(neighbours,1)>0
        dist = nnd2Sets(point,neighbours);
    else
        dist = NaN;
    end
end

