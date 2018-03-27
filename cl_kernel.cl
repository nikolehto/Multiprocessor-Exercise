void kernel simple_add(global const int* A, global const int* B, global int* C)
{       
    C[get_global_id(0)]=A[get_global_id(0)]+B[get_global_id(0)];                 
}

void resizeAndGreyScaleImg(global const unsigned char* img, global unsigned char* result_img, unsigned image_width, unsigned image_height, unsigned sampling_step)
{
	//const unsigned char r_con = 0.2126 * 255, g_con = 0.7152 * 255, b_con = 0.0722 * 255; // TODO (for performance somehow use char? maybe output should be shifted or something) 
	const float r_con = 0.2126f, g_con = 0.7152f, b_con = 0.0722f;

	const int result_pixel_index = get_global_id(0);
	
	// pixels above current index
	const int input_image_y_offset = (get_global_id(0) / image_width) * sampling_step * sampling_step * 4;
	// pixels above current index + x_index * sampling_step * rgba
	const int input_image_x_offset = (get_global_id(0) % image_width) * sampling_step * 4;
	const int input_image_index = input_image_y_offset + input_image_x_offset;

	result_img[result_pixel_index] = 255;//round(img[input_image_index] *r_con
		//+ img[input_image_index + 1] * g_con
		//+ img[input_image_index + 2] * b_con);



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

void kernel zncc_calc(global const unsigned char* l_img, global const unsigned char* r_img, global const unsigned char* l_mean_img, global const unsigned char* r_mean_img, global unsigned char* disp_img, unsigned img_width, unsigned img_height, unsigned win_size, int max_disparity)
{
	//calculating this on every time, dead weight
	const int win_rad_x = (win_size - 1) / 2;
	const int win_rad_y = (win_size - 1) / 2;

	const int img_size = img_width*img_height;

	int min_disparity = 0;
	const float scale_factor = (float)255 / (max_disparity - min_disparity); //scale factor may be negative, at least in c++ its ok to save negative values to unsigned (later scale_factor*d_index is casted to unsigned char)
	if (max_disparity < 0) // if max_disparity is negative swap min_disparity and max_disparity
	{
		min_disparity = max_disparity;
		max_disparity = 0;
	}

	const int pixel_index = get_global_id(0);


	const int pixel_x_coordinate = pixel_index % img_width;

	const int l_mean_value = l_mean_img[pixel_index];

	int winner_d_index = 0;
	//change to float
	float highest_correlation = 0.0f;

	for (int disp_x = min_disparity; disp_x< max_disparity; disp_x++)
	{
		if (pixel_x_coordinate + disp_x < 0 || pixel_x_coordinate + disp_x >= img_width)
		{
			continue;
		}

		float upper_sum = 0;
		float lower_sum_0 = 0;
		float lower_sum_1 = 0;

		const int r_mean_value = r_mean_img[pixel_index + disp_x];

		for (int win_y = -win_rad_y; win_y <= win_rad_y; win_y++)
		{
			//const int y_index = img_y + win_y;
			const int window_y_pixel_index = pixel_index + (win_y * img_width);
			if (window_y_pixel_index < 0 || window_y_pixel_index >= img_size)
			{
				continue;
			}

			for (int win_x = -win_rad_x; win_x <= win_rad_x; win_x++)
			{
				const int x_index = pixel_x_coordinate + win_x;
				const int x_disp_index = pixel_x_coordinate + win_x + disp_x;
				if (x_disp_index < 0
					|| x_disp_index >= img_width
					|| x_index < 0
					|| x_index >= img_width)
				{
					// how to deal with edges, if continue does it have any functionality or misfunctionality
					continue;
				}

				const int left_pixel_val_diff_from_avg = l_img[window_y_pixel_index + win_x] - l_mean_value;
				const int right_pixel_val_diff_from_avg = r_img[window_y_pixel_index + win_x + disp_x] - r_mean_value;
				upper_sum += left_pixel_val_diff_from_avg * right_pixel_val_diff_from_avg;
				lower_sum_0 += left_pixel_val_diff_from_avg * left_pixel_val_diff_from_avg;
				lower_sum_1 += right_pixel_val_diff_from_avg * right_pixel_val_diff_from_avg;
			}
		}

		const float lower_value = (sqrt(lower_sum_0) * sqrt(lower_sum_1));
		if (lower_value != 0.0f)
		{
			//change to float
			const float zncc_value = upper_sum / lower_value;
			if (zncc_value > highest_correlation)
			{
				highest_correlation = zncc_value;
				winner_d_index = disp_x;
			}
		}
	}
	disp_img[pixel_index] = round(winner_d_index * scale_factor);

}