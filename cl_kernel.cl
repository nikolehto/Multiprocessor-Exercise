void kernel simple_add(global const int* A, global const int* B, global int* C)
{       
    C[get_global_id(0)]=A[get_global_id(0)]+B[get_global_id(0)];                 
}   

void kernel mean_calc(global const unsigned char* img, global unsigned char* result_img, unsigned image_width, unsigned image_height, unsigned win_size)
{

	//TODO: This calculus gets performed everytime, and its waste of time
	const int win_rad_x = (win_size - 1) / 2;
	const int win_rad_y = (win_size - 1) / 2;

	const int img_size = image_width * image_height;

	unsigned int mean = 0;
	unsigned int value_count = 0;

	const int current_pixel_index = get_global_id(0);

	const int current_pixel_x_coordinate = current_pixel_index % image_width;

	for (int win_y = -win_rad_y; win_y <= win_rad_y; win_y++)
	{
		const int window_y_pixel_index = current_pixel_index + (win_y * image_width);
		if (window_y_pixel_index < 0 || window_y_pixel_index >= img_size)
		{
			continue;
		}

		for (int win_x = -win_rad_x; win_x <= win_rad_x; win_x++)
		{
			const int x_coordinate = current_pixel_x_coordinate + win_x;
			if (x_coordinate < 0 || (x_coordinate >= image_width))
			{
				continue;
			}

			int const current_window_pixel_index = window_y_pixel_index + win_x;

			mean += img[current_window_pixel_index];
			value_count++;
		}
	}

	mean /= value_count;

	result_img[current_pixel_index] = (unsigned char) mean;
}

void kernel cross_check(global const unsigned char* r_img, global const unsigned char* l_img, global unsigned char* result_img, unsigned image_width, unsigned image_height, unsigned max_diff)
{
	const int diff = l_img[get_global_id(0)] - r_img[get_global_id(0)];
	if (diff >= 0) // l_img is winner
	{
		if (diff <= max_diff)
		{
			result_img[get_global_id(0)] = l_img[get_global_id(0)];
		}
		else
		{
			result_img[get_global_id(0)] = 0;
		}
	}
	else //  r_img is winner
	{
		if (-diff <= max_diff)
		{
			result_img[get_global_id(0)] = r_img[get_global_id(0)];
		}
		else
		{
			result_img[get_global_id(0)] = 0;
		}

	}
}