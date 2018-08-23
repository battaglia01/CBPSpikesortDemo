%based on Julian Ehlers' answer here:
%https://www.mathworks.com/matlabcentral/answers/41238-turning-numbers-into-letters-based-on-alphabetical-order#comment_278707
function s = letters(d)
  b = 26;
  n = max(1,round(log2(d+1)/log2(b)));
  while (b^n <= d)
    n = n + 1;
  end
  s(n) = rem(d,b);
  while n > 1
    n = n - 1;
    d = floor(d/b);
    s(n) = rem(d,b);
  end
  n = length(s);
  while (n > 1)
    if (s(n) <= 0)
      s(n) = b + s(n);
      s(n-1) = s(n-1) - 1;
    end
    n = n - 1;
  end
  s(s<=0) = [];
  symbols = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  s = reshape(symbols(s),size(s));
end