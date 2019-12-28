close all;
clear
fid = fopen('FourPeople_1280x720_60.yuv','r');
fid2 = fopen('four_b.dat','w');

%------------------ size para 
row= 1280;col=720;
frames = 1;
%----------------------

Y = zeros(row,col);
UV = zeros(row,col/2);

U = zeros(row/2,col/2);
V = zeros(row/2,col/2);


%UU= zeros(row,col);
%VV= zeros(row,col);


for  frame = 1:frames
    
    [Y(:,:),count]  = fread(fid,[row,col],'uchar');
    [U(:,:),count1] = fread(fid,[row/2,col/2],'uchar');
    [V(:,:),count2] = fread(fid,[row/2,col/2],'uchar');
	
	for col_cnt = 1:col/2
		for row_cnt = 1:row
			if rem(row_cnt,2) ~= 0
				r = (row_cnt+1)/2;
				UV(row_cnt,col_cnt) = U(r,col_cnt);
			else
				r = row_cnt/2;
				UV(row_cnt,col_cnt) = V(r,col_cnt);
			end	
		end
	end
	
	for col_cnt = 1:col
		col_rem = rem(col_cnt,2);
		if col_rem == 0 %even
			for row_cnt = 1:row
				%test_dec = Y[row_cnt,col_cnt];
				test_y = lower(dec2hex(Y(row_cnt,col_cnt)));
				len_y = length(test_y);
				if len_y ~= 2
					test_y = ['0',test_y];
				end
				fprintf(fid2,'%s',test_y);
                fprintf(fid2,'\r\n');
			end
		else %odd
			c = (col_cnt+1)/2;
			for row_cnt = 1:row
				test_y = lower(dec2hex(Y(row_cnt,col_cnt)));
				test_uv = lower(dec2hex(UV(row_cnt,c)));
				len_y = length(test_y);
				len_uv = length(test_uv);
				if len_y ~= 2
					test_y = ['0',test_y];
				end
				if len_uv ~= 2
					test_uv = ['0',test_uv];
				end
				fprintf(fid2,'%s',test_y);
                fprintf(fid2,'\r\n');
				fprintf(fid2,'%s',test_uv);
                fprintf(fid2,'\r\n');
			end
		end
	end
end    
	
	
    

