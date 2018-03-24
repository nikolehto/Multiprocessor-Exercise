void kernel simple_add(global const int* A, global const int* B, global int* C)
{       
    C[get_global_id(0)]=A[get_global_id(0)]+B[get_global_id(0)];                 
}   

void kernel mean_calc(global const unsigned* img, global unsigned* r_img)
{
	r_img[get_global_id(0)] = img[get_global_id(0)];
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